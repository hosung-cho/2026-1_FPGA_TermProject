#!/usr/bin/env python3
"""
INT8 Reference Inference Simulator
===================================
하드웨어(CFU)와 동일한 정수 연산으로 LeNet-5 추론을 수행.
MAC4, RELU, MAXPOOL2, RESCALE 연산을 Python에서 정확히 재현.
"""

import os
import numpy as np
import struct

# ============================================================
# Hardware-matched operations
# ============================================================
def hw_mac4(a_bytes, b_bytes):
    """4-way INT8 dot product (matches cnn_cfu MAC4)"""
    result = 0
    for i in range(4):
        a_i = np.int8(a_bytes[i])
        b_i = np.int8(b_bytes[i])
        result += int(a_i) * int(b_i)
    return np.int32(result)

def hw_relu(x):
    """ReLU: max(x, 0) (matches cnn_cfu RELU)"""
    return np.int32(0) if x < 0 else np.int32(x)

def hw_maxpool2(a, b, c, d):
    """4-input uint8 max (matches cnn_cfu MAXPOOL2)"""
    return max(np.uint8(a), np.uint8(b), np.uint8(c), np.uint8(d))

def hw_rescale(val, shift):
    """Rescale with rounding and clamping (matches cnn_cfu RESCALE)"""
    val = int(val)
    if shift > 0:
        rounding = 1 << (shift - 1)
    else:
        rounding = 0
    rounded = val + rounding
    shifted = rounded >> shift  # arithmetic right shift
    if shifted < 0:
        return np.uint8(0)
    elif shifted > 255:
        return np.uint8(255)
    else:
        return np.uint8(shifted)


# ============================================================
# Layer functions using hardware-matched operations
# ============================================================
def conv2d_int8(input_uint8, weights_int8, bias_int32, shift, out_h, out_w, out_c, in_c, kh, kw):
    """INT8 convolution using MAC4-compatible operations"""
    output = np.zeros((out_h, out_w, out_c), dtype=np.uint8)
    
    for oc in range(out_c):
        for oh in range(out_h):
            for ow in range(out_w):
                acc = int(bias_int32[oc])
                
                # Accumulate over input channels and kernel
                for ic in range(in_c):
                    for ky in range(kh):
                        for kx in range(kw):
                            inp = int(np.int8(input_uint8[oh + ky, ow + kx, ic])) if input_uint8.ndim == 3 else int(np.int8(input_uint8[oh + ky, ow + kx]))
                            wgt = int(weights_int8[oc, ic, ky, kx]) if weights_int8.ndim == 4 else int(weights_int8[oc, ky, kx])
                            acc += inp * wgt
                
                # RESCALE + RELU (hardware does rescale then relu)
                scaled = hw_rescale(acc, shift)
                output[oh, ow, oc] = scaled  # rescale already clamps to [0,255] = implicit ReLU for positive
    
    return output

def maxpool2d_int8(input_uint8, pool_h, pool_w, stride):
    """2x2 MaxPooling using hardware-matched operations"""
    in_h, in_w = input_uint8.shape[0], input_uint8.shape[1]
    out_h = in_h // stride
    out_w = in_w // stride
    out_c = input_uint8.shape[2] if input_uint8.ndim == 3 else 1
    
    output = np.zeros((out_h, out_w, out_c), dtype=np.uint8)
    
    for c in range(out_c):
        for oh in range(out_h):
            for ow in range(out_w):
                a = input_uint8[oh*stride,     ow*stride,     c]
                b = input_uint8[oh*stride,     ow*stride + 1, c]
                c_val = input_uint8[oh*stride + 1, ow*stride,     c]
                d = input_uint8[oh*stride + 1, ow*stride + 1, c]
                output[oh, ow, c] = hw_maxpool2(a, b, c_val, d)
    
    return output

def fc_int8(input_uint8, weights_int8, bias_int32, shift, is_last=False):
    """INT8 fully connected layer"""
    input_flat = input_uint8.flatten().astype(np.int8)
    n_out = weights_int8.shape[0]
    
    if is_last:
        # Last layer: return raw INT32 for argmax (no rescale/relu)
        output = np.zeros(n_out, dtype=np.int32)
        for i in range(n_out):
            acc = int(bias_int32[i])
            for j in range(weights_int8.shape[1]):
                acc += int(input_flat[j]) * int(weights_int8[i, j])
            output[i] = acc
        return output
    else:
        output = np.zeros(n_out, dtype=np.uint8)
        for i in range(n_out):
            acc = int(bias_int32[i])
            for j in range(weights_int8.shape[1]):
                acc += int(input_flat[j]) * int(weights_int8[i, j])
            output[i] = hw_rescale(acc, shift)
        return output


# ============================================================
# Load quantized weights
# ============================================================
def load_weights(output_dir):
    """Load weights from the HEX file using memory map"""
    hex_path = os.path.join(output_dir, 'weights.hex')
    
    # Read all words
    words = []
    with open(hex_path, 'r') as f:
        for line in f:
            line = line.strip()
            if line and not line.startswith('//'):
                words.append(int(line, 16))
    
    # Convert to bytes (little-endian)
    all_bytes = bytearray()
    for w in words:
        all_bytes.extend(struct.pack('<I', w))
    
    # Memory map from weights_map.txt
    layers = {
        'conv1': {'w_off': 0x0000, 'w_cnt': 150, 'b_off': 0x0098, 'b_cnt': 6,
                  'shape': (6, 1, 5, 5), 'shift': 9},
        'conv2': {'w_off': 0x00B0, 'w_cnt': 2400, 'b_off': 0x0A10, 'b_cnt': 16,
                  'shape': (16, 6, 5, 5), 'shift': 12},
        'fc1':   {'w_off': 0x0A50, 'w_cnt': 30720, 'b_off': 0x8250, 'b_cnt': 120,
                  'shape': (120, 256), 'shift': 12},
        'fc2':   {'w_off': 0x8430, 'w_cnt': 10080, 'b_off': 0xAB90, 'b_cnt': 84,
                  'shape': (84, 120), 'shift': 11},
        'fc3':   {'w_off': 0xACE0, 'w_cnt': 840, 'b_off': 0xB028, 'b_cnt': 10,
                  'shape': (10, 84), 'shift': 11},
    }
    
    params = {}
    for name, info in layers.items():
        # Read weights as int8
        w_bytes = all_bytes[info['w_off']:info['w_off'] + info['w_cnt']]
        w_int8 = np.frombuffer(bytes(w_bytes), dtype=np.int8).reshape(info['shape'])
        
        # Read biases as int32
        b_bytes = all_bytes[info['b_off']:info['b_off'] + info['b_cnt'] * 4]
        b_int32 = np.frombuffer(bytes(b_bytes), dtype=np.int32)
        
        params[name] = {
            'weight': w_int8,
            'bias': b_int32,
            'shift': info['shift'],
        }
    
    return params


# ============================================================
# Full inference
# ============================================================
def inference(image_uint8, params):
    """Run full LeNet-5 INT8 inference"""
    # image_uint8: (28, 28) uint8
    
    # C1: Conv2d(1, 6, 5) + ReLU (implicit in rescale clamp)
    x = image_uint8.reshape(28, 28, 1) if image_uint8.ndim == 2 else image_uint8
    x = conv2d_int8(x, params['conv1']['weight'], params['conv1']['bias'],
                    params['conv1']['shift'], 24, 24, 6, 1, 5, 5)
    
    # S2: MaxPool2d(2, 2)
    x = maxpool2d_int8(x, 2, 2, 2)  # → 12x12x6
    
    # C3: Conv2d(6, 16, 5) + ReLU
    x = conv2d_int8(x, params['conv2']['weight'], params['conv2']['bias'],
                    params['conv2']['shift'], 8, 8, 16, 6, 5, 5)
    
    # S4: MaxPool2d(2, 2)
    x = maxpool2d_int8(x, 2, 2, 2)  # → 4x4x16
    
    # C5/FC1: Linear(256, 120) + ReLU
    x = fc_int8(x, params['fc1']['weight'], params['fc1']['bias'],
                params['fc1']['shift'])
    
    # F6/FC2: Linear(120, 84) + ReLU
    x = fc_int8(x, params['fc2']['weight'], params['fc2']['bias'],
                params['fc2']['shift'])
    
    # Output/FC3: Linear(84, 10) - no relu, raw output for argmax
    x = fc_int8(x, params['fc3']['weight'], params['fc3']['bias'],
                params['fc3']['shift'], is_last=True)
    
    return x


# ============================================================
# Main: Run inference on test images
# ============================================================
if __name__ == '__main__':
    script_dir = os.path.dirname(os.path.abspath(__file__))
    output_dir = os.path.join(script_dir, 'output')
    
    print("=" * 60)
    print("  INT8 Reference Inference (Hardware-Matched)")
    print("=" * 60)
    
    # Load weights
    params = load_weights(output_dir)
    print("  Loaded quantized weights from weights.hex")
    
    # Load test images
    from torchvision import datasets, transforms
    data_dir = os.path.join(script_dir, 'data')
    test_dataset = datasets.MNIST(data_dir, train=False, download=True,
                                   transform=transforms.ToTensor())
    
    # Run inference on first N images
    N = 100
    correct = 0
    print(f"\n  Running inference on {N} test images...\n")
    
    for i in range(N):
        img, label = test_dataset[i]
        img_uint8 = (img.squeeze().numpy() * 255).astype(np.uint8)
        
        output = inference(img_uint8, params)
        predicted = int(np.argmax(output))
        
        status = "✓" if predicted == label else "✗"
        if i < 20 or predicted != label:  # Print first 20 and all errors
            print(f"  Image {i:3d}: label={label}, predicted={predicted} {status}  "
                  f"scores={output.tolist()}")
        
        if predicted == label:
            correct += 1
    
    acc = 100.0 * correct / N
    print(f"\n  INT8 Hardware-Matched Accuracy: {correct}/{N} = {acc:.1f}%")
    
    # Export Conv1 intermediate results for RTL verification
    print("\n  Exporting Conv1 reference data for RTL verification...")
    img0, label0 = test_dataset[0]
    img0_uint8 = (img0.squeeze().numpy() * 255).astype(np.uint8)
    
    conv1_out = conv2d_int8(
        img0_uint8.reshape(28, 28, 1),
        params['conv1']['weight'], params['conv1']['bias'],
        params['conv1']['shift'], 24, 24, 6, 1, 5, 5
    )
    
    ref_path = os.path.join(output_dir, 'conv1_ref_output.txt')
    with open(ref_path, 'w') as f:
        f.write(f"// Conv1 output for image 0 (label={label0})\n")
        f.write(f"// Shape: 24x24x6, UINT8\n")
        for oc in range(6):
            f.write(f"\n// Filter {oc}:\n")
            for oh in range(24):
                row = [str(conv1_out[oh, ow, oc]) for ow in range(24)]
                f.write("  " + " ".join(f"{v:>3s}" for v in row) + "\n")
    
    print(f"  Saved: {ref_path}")
    print("\n" + "=" * 60)
