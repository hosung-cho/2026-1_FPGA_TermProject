#!/usr/bin/env python3
from pathlib import Path

INPUT_WORD = 0x00010000 >> 2
EXPECTED_WORD = 0x00010EFC >> 2
SAMPLE_WORDS = 256


def read_words(path):
    return [int(line.strip(), 16) for line in path.read_text().splitlines() if line.strip()]


def main():
    repo = Path(__file__).resolve().parents[3]
    fw = repo / "FPGA_proj" / "firmware"
    out = Path(__file__).with_name("lenet_samples.h")

    samples = []
    expected = []
    for digit in range(10):
        words = read_words(fw / f"lenet_digit{digit}_dmem.mem")
        samples.append(words[INPUT_WORD:INPUT_WORD + SAMPLE_WORDS])
        expected.append(words[EXPECTED_WORD])

    with out.open("w", newline="\n") as f:
        f.write("#ifndef LENET_SAMPLES_H\n#define LENET_SAMPLES_H\n\n")
        f.write("#include \"xil_types.h\"\n\n")
        f.write("#define LENET_SAMPLE_COUNT 10u\n")
        f.write("#define LENET_SAMPLE_WORDS 256u\n\n")
        f.write("static const u32 lenet_sample_expected[LENET_SAMPLE_COUNT] = {\n")
        f.write("    " + ", ".join(f"{value}u" for value in expected) + "\n")
        f.write("};\n\n")
        f.write("static const u32 lenet_sample_words[LENET_SAMPLE_COUNT][LENET_SAMPLE_WORDS] = {\n")
        for sample in samples:
            f.write("    {\n")
            for i in range(0, SAMPLE_WORDS, 8):
                chunk = sample[i:i + 8]
                f.write("        " + ", ".join(f"0x{value:08x}u" for value in chunk) + ",\n")
            f.write("    },\n")
        f.write("};\n\n")
        f.write("#endif\n")

    print(out)


if __name__ == "__main__":
    main()
