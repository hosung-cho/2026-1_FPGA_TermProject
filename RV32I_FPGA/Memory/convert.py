import os

def hex_to_c_array(filename, array_name):
    try:
        with open(filename, 'r') as f:
            lines = f.readlines()
            
        print(f"const u32 {array_name}[] = {{")
        for line in lines:
            line = line.strip()
            # 1. 어드레스 태그(@) 무시
            if line.startswith('@'):
                continue
            # 2. 빈 줄 무시
            if not line:
                continue
                
            # 3. 띄어쓰기로 구분된 여러 데이터 처리 (imem.hex처럼 한 줄에 여러 개 있을 경우 대비)
            words = line.split()
            for word in words:
                print(f"    0x{word},")
        print("};\n")
    except FileNotFoundError:
        print(f"Error: {filename} not found.")

# 실행
print("// --- Copy below this line to Vitis main.c ---")
hex_to_c_array('imem.hex', 'inst_array')
hex_to_c_array('dmem.hex', 'data_array')
print("// --- Copy above this line ---")