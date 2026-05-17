import os
import struct
import numpy as np

# Load weights and images
sd = os.path.dirname(os.path.abspath(__file__))
od = os.path.join(sd, 'output')

words = []
with open(os.path.join(od, 'weights.hex'), 'r') as f:
    for line in f:
        line = line.strip()
        if line and not line.startswith('//'):
            words.append(int(line, 16))
all_bytes = bytearray()
for w in words:
    all_bytes.extend(struct.pack('<I', w))

w_off = 0
w_cnt = 150
b_off = 152
b_cnt = 6

conv1_w = np.frombuffer(bytes(all_bytes[w_off:w_off + w_cnt]), dtype=np.int8).reshape(6, 1, 5, 5)
conv1_b = np.frombuffer(bytes(all_bytes[b_off:b_off + b_cnt * 4]), dtype=np.int32)

img_words = []
with open(os.path.join(od, 'test_images.hex'), 'r') as f:
    for line in f:
        line = line.strip()
        if line and not line.startswith('//'):
            img_words.append(int(line, 16))
img_bytes = bytearray()
for w in img_words:
    img_bytes.extend(struct.pack('<I', w))

img0 = np.frombuffer(bytes(img_bytes[:784]), dtype=np.uint8).reshape(28, 28)

c1_out = np.zeros((24, 24, 6), dtype=np.uint8)
shift = 9

print("=== Conv1 Non-zero Outputs ===")
for oc in range(6):
    non_zeros = []
    for oh in range(24):
        for ow in range(24):
            acc = int(conv1_b[oc])
            for ky in range(5):
                for kx in range(5):
                    px = int(img0[oh + ky, ow + kx])
                    wt = int(conv1_w[oc, 0, ky, kx])
                    acc += px * wt
            
            # Rescale + ReLU
            if acc < 0:
                val = 0
            else:
                val = (acc + (1 << (shift - 1))) >> shift
                val = min(255, max(0, val))
            c1_out[oh, ow, oc] = val
            if val > 0:
                non_zeros.append((oh, ow, val))
    print(f"Filter {oc}: found {len(non_zeros)} non-zero pixels. First few: {non_zeros[:10]}")
