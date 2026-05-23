#!/usr/bin/env python3
import argparse
from pathlib import Path


def normalize_hex_token(token: str) -> str:
    t = token.strip()
    if not t:
        return ""
    if t.startswith("0x") or t.startswith("0X"):
        t = t[2:]
    t = t.replace("_", "")
    return t.upper()


def read_hex_words(path: Path) -> list[str]:
    words: list[str] = []
    with path.open("r", encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            if line.startswith("#") or line.startswith("//"):
                continue
            for token in line.split():
                t = normalize_hex_token(token)
                if not t:
                    continue
                if len(t) > 8:
                    raise ValueError(f"Hex token too long: {t}")
                words.append(t.zfill(8))
    return words


def format_array(name: str, c_type: str, words: list[str], words_per_line: int) -> str:
    lines: list[str] = []
    lines.append(f"static const {c_type} {name}[] = {{")
    if words_per_line <= 0:
        words_per_line = 8
    line_parts: list[str] = []
    for i, w in enumerate(words):
        line_parts.append(f"0x{w}U")
        if (i + 1) % words_per_line == 0:
            lines.append("    " + ", ".join(line_parts) + ",")
            line_parts = []
    if line_parts:
        lines.append("    " + ", ".join(line_parts) + ",")
    lines.append("};")
    return "\n".join(lines) + "\n"


def main() -> int:
    parser = argparse.ArgumentParser(description="Convert hex words to a C array.")
    parser.add_argument("hex_file", help="Input .hex file (one 32-bit word per line).")
    parser.add_argument("--name", default=None, help="C array name. Defaults to file stem + '_image'.")
    parser.add_argument("--type", default="u32", help="C type for array elements (default: u32).")
    parser.add_argument("--words-per-line", type=int, default=8, help="Words per output line.")
    parser.add_argument("--output", default=None, help="Output file path (optional).")
    args = parser.parse_args()

    hex_path = Path(args.hex_file)
    if not hex_path.exists():
        raise FileNotFoundError(hex_path)

    name = args.name
    if not name:
        name = f"{hex_path.stem}_image"

    words = read_hex_words(hex_path)
    out_text = format_array(name, args.type, words, args.words_per_line)

    if args.output:
        out_path = Path(args.output)
        out_path.write_text(out_text, encoding="utf-8")
    else:
        print(out_text, end="")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
