#!/usr/bin/env python3
"""
LeNet-5 MNIST Training + INT8 Quantization + HEX Export
========================================================
1. FP32 모델 학습 (5 epochs)
2. Post-Training Static Quantization (PTQ)
3. INT8 가중치 + scale/shift 파라미터 추출
4. C 헤더 파일 및 HEX 파일 생성
"""

import os
import struct
import numpy as np
import torch
import torch.nn as nn
import torch.optim as optim
from torchvision import datasets, transforms
from torch.utils.data import DataLoader

# ============================================================
# 1. 모델 정의 (우리 수정 LeNet-5)
# ============================================================
class LeNet5_MNIST(nn.Module):
    """
    Modified LeNet-5 for 28x28 MNIST:
    C1: Conv2d(1, 6, 5, valid) → 24x24x6
    S2: MaxPool2d(2, 2)        → 12x12x6
    C3: Conv2d(6, 16, 5, valid)→ 8x8x16
    S4: MaxPool2d(2, 2)        → 4x4x16
    C5: Linear(256, 120)
    F6: Linear(120, 84)
    OUT: Linear(84, 10)
    """
    def __init__(self):
        super().__init__()
        self.conv1 = nn.Conv2d(1, 6, 5)         # C1
        self.pool  = nn.MaxPool2d(2, 2)          # S2, S4
        self.conv2 = nn.Conv2d(6, 16, 5)         # C3
        self.fc1   = nn.Linear(4*4*16, 120)      # C5
        self.fc2   = nn.Linear(120, 84)          # F6
        self.fc3   = nn.Linear(84, 10)           # Output
        self.relu  = nn.ReLU()

    def forward(self, x):
        x = self.relu(self.conv1(x))   # 28→24
        x = self.pool(x)               # 24→12
        x = self.relu(self.conv2(x))   # 12→8
        x = self.pool(x)               # 8→4
        x = x.view(-1, 4*4*16)         # Flatten
        x = self.relu(self.fc1(x))
        x = self.relu(self.fc2(x))
        x = self.fc3(x)
        return x


# ============================================================
# 2. 학습
# ============================================================
def train_model():
    print("=" * 60)
    print("  Step 1: FP32 Model Training")
    print("=" * 60)

    transform = transforms.Compose([
        transforms.ToTensor(),
        transforms.Normalize((0.1307,), (0.3081,))
    ])

    # MNIST 데이터 다운로드
    data_dir = os.path.join(os.path.dirname(__file__), 'data')
    train_dataset = datasets.MNIST(data_dir, train=True, download=True, transform=transform)
    test_dataset  = datasets.MNIST(data_dir, train=False, download=True, transform=transform)

    train_loader = DataLoader(train_dataset, batch_size=128, shuffle=True, num_workers=2)
    test_loader  = DataLoader(test_dataset,  batch_size=256, shuffle=False, num_workers=2)

    model = LeNet5_MNIST()
    criterion = nn.CrossEntropyLoss()
    optimizer = optim.Adam(model.parameters(), lr=0.001)

    # Training
    for epoch in range(5):
        model.train()
        running_loss = 0.0
        correct = 0
        total = 0
        for batch_idx, (data, target) in enumerate(train_loader):
            optimizer.zero_grad()
            output = model(data)
            loss = criterion(output, target)
            loss.backward()
            optimizer.step()
            running_loss += loss.item()
            _, predicted = output.max(1)
            total += target.size(0)
            correct += predicted.eq(target).sum().item()

        # Evaluate
        model.eval()
        test_correct = 0
        test_total = 0
        with torch.no_grad():
            for data, target in test_loader:
                output = model(data)
                _, predicted = output.max(1)
                test_total += target.size(0)
                test_correct += predicted.eq(target).sum().item()

        train_acc = 100. * correct / total
        test_acc  = 100. * test_correct / test_total
        print(f"  Epoch {epoch+1}/5 | Loss: {running_loss/len(train_loader):.4f} | "
              f"Train: {train_acc:.2f}% | Test: {test_acc:.2f}%")

    print(f"\n  Final FP32 Test Accuracy: {test_acc:.2f}%")

    # Save FP32 model
    output_dir = os.path.join(os.path.dirname(__file__), 'output')
    os.makedirs(output_dir, exist_ok=True)
    torch.save(model.state_dict(), os.path.join(output_dir, 'lenet5_fp32.pth'))
    print(f"  Saved: output/lenet5_fp32.pth")

    return model, test_loader


# ============================================================
# 3. INT8 양자화 (Per-Layer Symmetric Quantization - 수동)
# ============================================================
def quantize_manual(model):
    """
    수동 per-layer symmetric INT8 양자화.
    RTL 하드웨어와 정확히 일치하는 양자화 방식.
    
    각 레이어에서:
    - weight_int8 = round(weight_fp32 / scale) , clamp to [-128, 127]
    - scale = max(|weight_fp32|) / 127
    - 입력도 양자화되므로, 출력 = sum(input_int8 * weight_int8) 
    - rescale_shift: 출력을 다시 INT8로 변환할 때 사용할 shift 값
    """
    print("\n" + "=" * 60)
    print("  Step 2: Manual INT8 Quantization")
    print("=" * 60)

    model.eval()
    quant_params = {}

    layers = [
        ('conv1', model.conv1),
        ('conv2', model.conv2),
        ('fc1',   model.fc1),
        ('fc2',   model.fc2),
        ('fc3',   model.fc3),
    ]

    for name, layer in layers:
        w = layer.weight.data.numpy()
        b = layer.bias.data.numpy()

        # Per-layer symmetric quantization
        w_max = np.max(np.abs(w))
        w_scale = w_max / 127.0

        # Quantize weights to INT8
        w_int8 = np.round(w / w_scale).astype(np.int8)

        # Quantize bias to INT32 (bias uses input_scale * weight_scale)
        # For simplicity, we'll use a separate bias scale
        b_scale = w_scale  # simplified: assume input_scale ≈ 1/255
        b_int32 = np.round(b / b_scale).astype(np.int32)

        # Calculate rescale shift (approximate)
        # output = sum(input_uint8 * weight_int8) + bias_int32
        # To convert back to uint8: output >> shift
        # shift = log2(accumulator_range / 255)
        # Heuristic: based on weight scale and expected input range
        if 'conv' in name:
            kernel_size = w.shape[2] * w.shape[3]
            in_channels = w.shape[1]
            n_macs = kernel_size * in_channels
        else:
            n_macs = w.shape[1]

        # Estimate the rescale shift
        # accumulator ≈ n_macs * 127 * 127 (worst case)
        # We want to map this to [0, 255]
        acc_max = n_macs * 127 * 64  # typical case (not worst)
        if acc_max > 0:
            shift = max(0, int(np.floor(np.log2(acc_max / 255.0))))
        else:
            shift = 0

        quant_params[name] = {
            'weight_int8': w_int8,
            'bias_int32': b_int32,
            'w_scale': w_scale,
            'shift': shift,
            'shape': w.shape,
        }

        print(f"  {name:6s} | shape={str(w.shape):20s} | "
              f"w_scale={w_scale:.6f} | shift={shift:2d} | "
              f"w_range=[{w_int8.min()}, {w_int8.max()}]")

    return quant_params


# ============================================================
# 4. INT8 모델 정확도 검증
# ============================================================
def verify_int8(model, quant_params, test_loader):
    """FP32 모델에 양자화 가중치를 다시 넣어서 정확도 확인"""
    print("\n" + "=" * 60)
    print("  Step 3: INT8 Accuracy Verification")
    print("=" * 60)

    # 양자화된 가중치를 FP32로 복원하여 테스트
    model_copy = LeNet5_MNIST()
    model_copy.load_state_dict(model.state_dict())

    layers = {
        'conv1': model_copy.conv1,
        'conv2': model_copy.conv2,
        'fc1':   model_copy.fc1,
        'fc2':   model_copy.fc2,
        'fc3':   model_copy.fc3,
    }

    for name, layer in layers.items():
        qp = quant_params[name]
        # Dequantize: weight_fp32_approx = weight_int8 * scale
        w_deq = torch.tensor(qp['weight_int8'].astype(np.float32) * qp['w_scale'])
        b_deq = torch.tensor(qp['bias_int32'].astype(np.float32) * qp['w_scale'])
        layer.weight.data = w_deq
        layer.bias.data = b_deq

    model_copy.eval()
    correct = 0
    total = 0
    with torch.no_grad():
        for data, target in test_loader:
            output = model_copy(data)
            _, predicted = output.max(1)
            total += target.size(0)
            correct += predicted.eq(target).sum().item()

    acc = 100. * correct / total
    print(f"  INT8 (dequantized) Test Accuracy: {acc:.2f}%")
    return acc


# ============================================================
# 5. C 헤더 파일 생성
# ============================================================
def export_c_header(quant_params, output_dir):
    print("\n" + "=" * 60)
    print("  Step 4: Export C Header & HEX Files")
    print("=" * 60)

    header_path = os.path.join(output_dir, 'weights.h')
    with open(header_path, 'w') as f:
        f.write("// Auto-generated LeNet-5 INT8 weights\n")
        f.write("// Do not edit manually\n\n")
        f.write("#ifndef LENET5_WEIGHTS_H\n")
        f.write("#define LENET5_WEIGHTS_H\n\n")
        f.write("#include <stdint.h>\n\n")

        for name, qp in quant_params.items():
            w = qp['weight_int8']
            b = qp['bias_int32']
            shift = qp['shift']
            shape = qp['shape']

            f.write(f"// {name}: shape={shape}, scale={qp['w_scale']:.6f}, shift={shift}\n")
            f.write(f"#define {name.upper()}_SHIFT {shift}\n")

            # Flatten weights
            w_flat = w.flatten()
            f.write(f"const int8_t {name}_weights[{len(w_flat)}] = {{\n")
            for i in range(0, len(w_flat), 16):
                chunk = w_flat[i:i+16]
                f.write("    " + ", ".join(f"{v:4d}" for v in chunk) + ",\n")
            f.write("};\n\n")

            # Bias
            b_flat = b.flatten()
            f.write(f"const int32_t {name}_bias[{len(b_flat)}] = {{\n")
            for i in range(0, len(b_flat), 8):
                chunk = b_flat[i:i+8]
                f.write("    " + ", ".join(f"{v:6d}" for v in chunk) + ",\n")
            f.write("};\n\n")

        f.write("#endif // LENET5_WEIGHTS_H\n")

    print(f"  Saved: {header_path}")


# ============================================================
# 6. HEX 파일 생성 (가중치를 BRAM에 로드하기 위한 HEX)
# ============================================================
def export_hex(quant_params, output_dir):
    """가중치를 4바이트씩 패킹하여 HEX 파일로 출력"""
    hex_path = os.path.join(output_dir, 'weights.hex')
    info_path = os.path.join(output_dir, 'weights_map.txt')

    all_bytes = bytearray()
    offset_map = {}

    for name, qp in quant_params.items():
        w = qp['weight_int8'].flatten()
        b = qp['bias_int32'].flatten()

        # Record offset
        offset_map[name] = {
            'weight_offset': len(all_bytes),
            'weight_count': len(w),
        }

        # Pack weights (INT8, 4 bytes per word)
        # Pad to 4-byte boundary
        padded_w = np.pad(w, (0, (4 - len(w) % 4) % 4), constant_values=0)
        all_bytes.extend(padded_w.astype(np.uint8).tobytes())

        # Record bias offset
        offset_map[name]['bias_offset'] = len(all_bytes)
        offset_map[name]['bias_count'] = len(b)

        # Pack biases (INT32, already 4 bytes each)
        for val in b:
            all_bytes.extend(struct.pack('<i', int(val)))

    # Write HEX file (32-bit words)
    with open(hex_path, 'w') as f:
        for i in range(0, len(all_bytes), 4):
            word = int.from_bytes(all_bytes[i:i+4], byteorder='little')
            f.write(f"{word:08X}\n")

    # Write memory map info
    with open(info_path, 'w') as f:
        f.write("LeNet-5 Weight Memory Map\n")
        f.write("=" * 50 + "\n\n")
        for name, info in offset_map.items():
            qp = quant_params[name]
            f.write(f"[{name}]\n")
            f.write(f"  weight_offset = 0x{info['weight_offset']:04X} ({info['weight_offset']})\n")
            f.write(f"  weight_count  = {info['weight_count']}\n")
            f.write(f"  bias_offset   = 0x{info['bias_offset']:04X} ({info['bias_offset']})\n")
            f.write(f"  bias_count    = {info['bias_count']}\n")
            f.write(f"  shift         = {qp['shift']}\n")
            f.write(f"  shape         = {qp['shape']}\n\n")
        f.write(f"Total size: {len(all_bytes)} bytes ({len(all_bytes)//1024} KB)\n")

    print(f"  Saved: {hex_path} ({len(all_bytes)} bytes)")
    print(f"  Saved: {info_path}")
    return offset_map


# ============================================================
# 7. 테스트 이미지 HEX 추출
# ============================================================
def export_test_images(output_dir, num_images=10):
    """MNIST 테스트 이미지를 UINT8로 변환하여 HEX 파일로 저장"""
    data_dir = os.path.join(os.path.dirname(__file__), 'data')
    test_dataset = datasets.MNIST(data_dir, train=False, download=True,
                                   transform=transforms.ToTensor())

    img_hex_path = os.path.join(output_dir, 'test_images.hex')
    label_path = os.path.join(output_dir, 'test_labels.txt')

    with open(img_hex_path, 'w') as f_hex, open(label_path, 'w') as f_lbl:
        for i in range(num_images):
            img, label = test_dataset[i]
            # img is [1, 28, 28] float [0, 1] → convert to uint8 [0, 255]
            img_uint8 = (img.squeeze().numpy() * 255).astype(np.uint8)
            img_flat = img_uint8.flatten()  # 784 bytes

            f_hex.write(f"// Image {i}, label={label}\n")
            # Pack 4 bytes per word
            for j in range(0, len(img_flat), 4):
                word = int.from_bytes(img_flat[j:j+4], byteorder='little')
                f_hex.write(f"{word:08X}\n")

            f_lbl.write(f"Image {i}: label={label}\n")

    print(f"  Saved: {img_hex_path} ({num_images} images)")
    print(f"  Saved: {label_path}")


# ============================================================
# Main
# ============================================================
if __name__ == '__main__':
    # Step 1: Train
    model, test_loader = train_model()

    # Step 2: Quantize
    quant_params = quantize_manual(model)

    # Step 3: Verify
    int8_acc = verify_int8(model, quant_params, test_loader)

    # Step 4: Export
    output_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'output')
    os.makedirs(output_dir, exist_ok=True)
    export_c_header(quant_params, output_dir)

    # Step 5: HEX
    export_hex(quant_params, output_dir)

    # Step 6: Test images
    export_test_images(output_dir)

    print("\n" + "=" * 60)
    print("  All Done!")
    print(f"  FP32 Accuracy → INT8 Accuracy: {int8_acc:.2f}%")
    print(f"  Output directory: {output_dir}")
    print("=" * 60)
