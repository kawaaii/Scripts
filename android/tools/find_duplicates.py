#!/usr/bin/env python3

import sys

def find_duplicates(filename):
    """Finds duplicate entries in a file.

    Args:
        filename: The name of the file to search.

    Returns:
        A dictionary containing line numbers as keys and lists of duplicate entries as values.
    """

    with open(filename, "r") as f:
        lines = f.readlines()

    line_number_dict = {}
    seen = set()

    for index, line in enumerate(lines):
        line = line.strip()
        if not line:
            continue
        if line in seen:
            if line:
                if line in line_number_dict:
                    line_number_dict[line].append(index + 1)
                else:
                    line_number_dict[line] = [index + 1]
        else:
            seen.add(line)

    return line_number_dict

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python find_duplicates.py <filename>")
        sys.exit(1)

    filename = sys.argv[1]
    line_number_dict = find_duplicates(filename)

    if not line_number_dict:
        print("No duplicate entries found.")
    else:
        print("Duplicate entries:")
        for line, line_numbers in line_number_dict.items():
            if line:
                print(f"Line: {', '.join(str(num) for num in line_numbers)} - Entry: {line}")
            else:
                print(f"Line: {', '.join(str(num) for num in line_numbers)} - Entry: <empty>")
