#!/usr/bin/env python3

import argparse
import re
from pathlib import Path


TOKEN_RE = re.compile(r"@([0-9A-Fa-f]+)|([0-9A-Fa-f]{1,8})")
DEFAULT_DEPTH = 128 * 1024 // 4


def parse_vmem(path: Path) -> dict[int, int]:
    content = path.read_text()
    content = re.sub(r"/\*.*?\*/", "", content, flags=re.DOTALL)

    words: dict[int, int] = {}
    address = 0
    for token in TOKEN_RE.finditer(content):
        address_token, word_token = token.groups()
        if address_token is not None:
            address = int(address_token, 16)
            continue

        words[address] = int(word_token, 16)
        address += 1

    return words


def write_mif(path: Path, words: dict[int, int], depth: int) -> None:
    if any(address < 0 or address >= depth for address in words):
        raise ValueError(f"VMEM address exceeds configured MIF depth ({depth} words)")

    address_width = max(1, (depth - 1).bit_length() // 4 + ((depth - 1).bit_length() % 4 != 0))
    with path.open("w") as file:
        file.write("WIDTH=32;\n")
        file.write(f"DEPTH={depth};\n")
        file.write("ADDRESS_RADIX=HEX;\n")
        file.write("DATA_RADIX=HEX;\n\n")
        file.write("CONTENT BEGIN\n")
        for address in range(depth):
            value = words.get(address, 0)
            file.write(f"    {address:0{address_width}X} : {value:08X};\n")
        file.write("END;\n")


def main() -> None:
    parser = argparse.ArgumentParser(description="Convert a VMEM file to an Altera MIF file")
    parser.add_argument("input", type=Path, help="input VMEM file")
    parser.add_argument("-o", "--output", type=Path, help="output MIF file")
    parser.add_argument(
        "--depth",
        type=int,
        default=DEFAULT_DEPTH,
        help=f"MIF depth in 32-bit words (default: {DEFAULT_DEPTH})",
    )
    args = parser.parse_args()

    if args.depth <= 0:
        parser.error("--depth must be positive")

    output = args.output or args.input.with_suffix(".mif")
    words = parse_vmem(args.input)
    write_mif(output, words, args.depth)
    print(f"Converted {args.input} ({len(words)} initialized words) to {output}")


if __name__ == "__main__":
    main()
