"""Write a flat little-endian binary as 32-bit words for $readmemh."""

from pathlib import Path
import sys


def main():
    binary, vmem = map(Path, sys.argv[1:])
    data = binary.read_bytes()
    with vmem.open("w", encoding="ascii") as output:
        output.write("@00000000\n")
        for offset in range(0, len(data), 4):
            word = int.from_bytes(data[offset:offset + 4], "little")
            output.write(f"{word:08x}\n")


if __name__ == "__main__":
    main()
