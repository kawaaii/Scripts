#!/usr/bin/env python3

import sys

def find_duplicates(filename):
  """Finds duplicate entries in a file.

  Args:
    filename: The name of the file to search.

  Returns:
    A list of duplicate entries.
  """

  with open(filename, "r") as f:
    lines = f.readlines()

  seen = set()
  duplicates = []

  for line in lines:
    line = line.strip()
    if line in seen and line != "\n":
      duplicates.append(line)
    else:
      seen.add(line)

  return duplicates

if __name__ == "__main__":
  if len(sys.argv) != 2:
    print("Usage: python find_duplicates.py <filename>")
    sys.exit(1)

  filename = sys.argv[1]
  duplicates = find_duplicates(filename)

  if not duplicates:
    print("No duplicate entries found.")
  else:
    print("Duplicate entries:", end="")
    for duplicate in duplicates:
      print("  " + duplicate.replace("\n", "")
