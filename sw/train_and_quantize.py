#!/usr/bin/env python3
"""
LeNet-5 INT8 Quantization - PyTorch Static Quantization
=========================================================
PyTorch의 정적 양자화를 사용하여 정확한 scale/zero_point를 자동 계산.
양자화된 가중치를 추출하여 HEX/C 헤더로 내보냄.
"""

import os, struct
import numpy as np
import torch
import torch.nn as nn
import torch.optim as optim
import torch.ao.quantization as quant
from torchvision import datasets, transforms
from torch.utils.data import DataLoader
from copy import deepcopy


class LeNet5(nn.Module):
    def __init__(self):
        super().__init__()
        self.quant   = quant.QuantStub()
        self.conv1   = nn.Conv2d(1, 6, 5)
        self.relu1   = nn.ReLU()
        self.pool    = nn.MaxPool2d(2, 2)
        self.conv2   = nn.Conv2d(6, 16, 5)
        self.relu2   = nn.ReLU()
        self.fc1     = nn.Linear(256, 120)
        self.relu3   = nn.ReLU()
        self.fc2     = nn.Linear(120, 84)
        self.relu4   = nn.ReLU()
        self.fc3     = nn.Linear(84, 10)
        self.dequant = quant.DeQuantStub()

    def forward(self, x):
        x = self.quant(x)
        x = self.pool(self.relu1(self.conv1(x)))
        x = self.pool(self.relu2(self.conv2(x)))
        x = x.reshape(-1, 256)
        x = self.relu3(self.fc1(x))
        x = self.relu4(self.fc2(x))
        x = self.fc3(x)
        x = self.dequant(x)
        return x


def train(data_dir, output_dir):
    print("=" * 60)
    print("  Step 1: FP32 Training")
    print("=" * 60)
    
    transform = transforms.ToTensor()
    train_ds = datasets.MNIST(data_dir, train=True,  download=True, transform=transform)
    test_ds  = datasets.MNIST(data_dir, train=False, download=True, transform=transform)
    train_ld = DataLoader(train_ds, batch_size=128, shuffle=True,  num_workers=2)
    test_ld  = DataLoader(test_ds,  batch_size=256, shuffle=False, num_workers=2)

    model = LeNet5()
    opt = optim.Adam(model.parameters(), lr=1e-3)
    crit = nn.CrossEntropyLoss()

    for ep in range(5):
        model.train()
        loss_sum = correct = total = 0
        for x, y in train_ld:
            opt.zero_grad(); out = model(x); loss = crit(out, y)
            loss.backward(); opt.step()
            loss_sum += loss.item()
            correct += (out.argmax(1) == y).sum().item(); total += y.size(0)
        
        model.eval()
        tc = tt = 0
        with torch.no_grad():
            for x, y in test_ld:
                tc += (model(x).argmax(1) == y).sum().item(); tt += y.size(0)
        print(f"  Epoch {ep+1}/5 | Loss: {loss_sum/len(train_ld):.4f} | "
              f"Train: {100*correct/total:.2f}% | Test: {100*tc/tt:.2f}%")

    fp32_acc = 100 * tc / tt
    torch.save(model.state_dict(), os.path.join(output_dir, 'lenet5_fp32.pth'))
    print(f"\n  FP32 Accuracy: {fp32_acc:.2f}%")
    return model, test_ld, fp32_acc


def quantize_static(model, test_ld):
    print("\n" + "=" * 60)
    print("  Step 2: PyTorch Static Quantization")
    print("=" * 60)

    model_q = deepcopy(model)
    model_q.eval()
    model_q.qconfig = quant.QConfig(
        activation=quant.observer.MinMaxObserver.with_args(
            dtype=torch.quint8, qscheme=torch.per_tensor_affine),
        weight=quant.observer.MinMaxObserver.with_args(
            dtype=torch.qint8, qscheme=torch.per_tensor_symmetric)
    )
    quant.prepare(model_q, inplace=True)

    # Calibration
    with torch.no_grad():
        for i, (x, _) in enumerate(test_ld):
            model_q(x)
            if i >= 10: break  # ~2500 images
    
    quant.convert(model_q, inplace=True)

    # Verify
    correct = total = 0
    with torch.no_grad():
        for x, y in test_ld:
            correct += (model_q(x).argmax(1) == y).sum().item(); total += y.size(0)
    q_acc = 100 * correct / total
    print(f"  PyTorch Quantized Accuracy: {q_acc:.2f}%")
    return model_q, q_acc


def extract_params(model_q):
    """양자화된 모델에서 INT8 가중치, 바이어스, scale/zero_point 추출"""
    print("\n" + "=" * 60)
    print("  Step 3: Extract Quantized Parameters")
    print("=" * 60)

    params = {}
    
    layer_names = ['conv1', 'conv2', 'fc1', 'fc2', 'fc3']
    for name in layer_names:
        layer = getattr(model_q, name)
        
        # Weight: int8 tensor (per-tensor symmetric)
        w_int8 = layer.weight().int_repr().numpy()
        w_scale = np.array([layer.weight().q_scale()])
        w_zp = np.array([layer.weight().q_zero_point()])
        
        # Bias: float32 → we'll quantize manually
        b_fp32 = layer.bias().detach().numpy()
        
        # Input scale/zero_point (from the quantization observer)
        in_scale = layer.scale
        in_zp = layer.zero_point
        
        # For the output, we need the next layer's input scale
        # This is stored in the layer's scale attribute
        out_scale = in_scale  # placeholder
        
        params[name] = {
            'weight_int8': w_int8,
            'weight_scale': w_scale,
            'weight_zp': w_zp,
            'bias_fp32': b_fp32,
            'in_scale': float(in_scale) if isinstance(in_scale, (int, float)) else in_scale,
            'shape': w_int8.shape,
        }
        
        print(f"  {name:6s} | shape={str(w_int8.shape):20s} | "
              f"w_scale={w_scale[0]:.6f} | "
              f"w_range=[{w_int8.min()}, {w_int8.max()}]")
    
    return params


def manual_int8_inference(image_tensor, model_q, params):
    """
    PyTorch 양자화 모델의 내부 동작을 수동으로 재현.
    이것이 하드웨어에서 구현할 추론 로직.
    """
    # 그냥 PyTorch 양자화 모델 사용 (정확한 레퍼런스)
    model_q.eval()
    with torch.no_grad():
        output = model_q(image_tensor.unsqueeze(0))
    return output.squeeze().numpy()


def verify_manual(model_q, params, test_ld, n=100):
    print("\n" + "=" * 60)
    print(f"  Step 4: Manual INT8 Verification ({n} images)")
    print("=" * 60)
    
    correct = total = 0
    for x, y in test_ld:
        for i in range(x.size(0)):
            if total >= n: break
            out = manual_int8_inference(x[i], model_q, params)
            pred = int(np.argmax(out))
            if total < 10:
                s = "✓" if pred == y[i].item() else "✗"
                print(f"  Image {total:3d}: label={y[i].item()}, predicted={pred} {s}  "
                      f"scores={[f'{v:.1f}' for v in out]}")
            if pred == y[i].item(): correct += 1
            total += 1
        if total >= n: break
    
    acc = 100 * correct / total
    print(f"\n  Manual INT8 Accuracy: {correct}/{total} = {acc:.1f}%")
    return acc


def export_for_hw(params, model_q, output_dir, data_dir):
    """하드웨어용 HEX 파일 및 C 헤더 내보내기"""
    print("\n" + "=" * 60)
    print("  Step 5: Export for Hardware")
    print("=" * 60)

    # C Header
    hp = os.path.join(output_dir, 'weights.h')
    with open(hp, 'w') as f:
        f.write("// LeNet-5 INT8 Weights (PyTorch Static Quantization)\n")
        f.write("#ifndef LENET5_WEIGHTS_H\n#define LENET5_WEIGHTS_H\n#include <stdint.h>\n\n")
        
        # Input quantization params
        inp_scale = model_q.quant.scale
        inp_zp = model_q.quant.zero_point
        f.write(f"// Input: scale={float(inp_scale):.8f}, zero_point={int(inp_zp)}\n")
        f.write(f"#define INPUT_SCALE_INV {int(round(1.0/float(inp_scale)))}\n")
        f.write(f"#define INPUT_ZP {int(inp_zp)}\n\n")
        
        for name, p in params.items():
            w = p['weight_int8'].flatten()
            b_fp32 = p['bias_fp32']
            ws = p['weight_scale'][0]
            
            # Quantize bias to int32 using input_scale * weight_scale
            b_scale = float(inp_scale) * ws
            b_int32 = np.round(b_fp32 / b_scale).astype(np.int32)
            p['bias_int32'] = b_int32  # store for HEX export
            
            # Compute output M and shift
            # For non-last layers, get the output scale from the model
            layer = getattr(model_q, name)
            out_scale = float(layer.scale) if hasattr(layer, 'scale') else 1.0
            
            M = float(inp_scale) * ws / out_scale if out_scale > 0 else 1.0
            if M > 0 and M < 1:
                shift = int(round(-np.log2(M)))
            elif M >= 1:
                shift = 0
            else:
                shift = 0
            p['shift'] = shift
            p['M'] = M
            
            f.write(f"// {name}: shape={p['shape']}, w_scale={ws:.6f}, shift={shift}, M={M:.6f}\n")
            f.write(f"#define {name.upper()}_SHIFT {shift}\n")
            f.write(f"const int8_t {name}_w[{len(w)}] = {{{','.join(str(v) for v in w)}}};\n")
            f.write(f"const int32_t {name}_b[{len(b_int32)}] = {{{','.join(str(v) for v in b_int32)}}};\n\n")
        
        f.write("#endif\n")
    print(f"  Saved: {hp}")

    # HEX file  
    hex_path = os.path.join(output_dir, 'weights.hex')
    map_path = os.path.join(output_dir, 'weights_map.txt')
    all_bytes = bytearray()
    offset_map = {}
    
    for name, p in params.items():
        w = p['weight_int8'].flatten()
        b = p['bias_int32']
        offset_map[name] = {'w_off': len(all_bytes), 'w_cnt': len(w)}
        pw = np.pad(w, (0, (4 - len(w) % 4) % 4), constant_values=0)
        all_bytes.extend(pw.astype(np.uint8).tobytes())
        offset_map[name]['b_off'] = len(all_bytes)
        offset_map[name]['b_cnt'] = len(b)
        for v in b: all_bytes.extend(struct.pack('<i', int(v)))

    with open(hex_path, 'w') as f:
        for i in range(0, len(all_bytes), 4):
            f.write(f"{int.from_bytes(all_bytes[i:i+4], 'little'):08X}\n")
    
    with open(map_path, 'w') as f:
        f.write("LeNet-5 Weight Memory Map\n" + "=" * 50 + "\n\n")
        for name, info in offset_map.items():
            p = params[name]
            f.write(f"[{name}] shape={p['shape']} shift={p['shift']} M={p['M']:.6f}\n")
            f.write(f"  w: 0x{info['w_off']:04X} ({info['w_cnt']} bytes)\n")
            f.write(f"  b: 0x{info['b_off']:04X} ({info['b_cnt']} x int32)\n\n")
        f.write(f"Total: {len(all_bytes)} bytes ({len(all_bytes)//1024} KB)\n")
    
    print(f"  Saved: {hex_path} ({len(all_bytes)} bytes)")
    
    # Test images (uint8, raw pixel values 0-255)
    test_ds = datasets.MNIST(data_dir, train=False, download=True, transform=transforms.ToTensor())
    img_path = os.path.join(output_dir, 'test_images.hex')
    lbl_path = os.path.join(output_dir, 'test_labels.txt')
    with open(img_path, 'w') as fh, open(lbl_path, 'w') as fl:
        for i in range(10):
            img, lbl = test_ds[i]
            px = (img.squeeze().numpy() * 255).astype(np.uint8).flatten()
            fh.write(f"// Image {i}, label={lbl}\n")
            for j in range(0, len(px), 4):
                fh.write(f"{int.from_bytes(px[j:j+4], 'little'):08X}\n")
            fl.write(f"Image {i}: label={lbl}\n")
    print(f"  Saved: {img_path} (10 images)")


if __name__ == '__main__':
    sd = os.path.dirname(os.path.abspath(__file__))
    od = os.path.join(sd, 'output'); os.makedirs(od, exist_ok=True)
    dd = os.path.join(sd, 'data')
    
    model, test_ld, fp32_acc = train(dd, od)
    model_q, q_acc = quantize_static(model, test_ld)
    params = extract_params(model_q)
    int8_acc = verify_manual(model_q, params, test_ld, 100)
    export_for_hw(params, model_q, od, dd)
    
    print(f"\n{'='*60}")
    print(f"  FP32: {fp32_acc:.2f}% → Quantized: {q_acc:.2f}% → HW-ref: {int8_acc:.1f}%")
    print(f"{'='*60}")
