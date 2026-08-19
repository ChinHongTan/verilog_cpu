#!/usr/bin/env python3
import sys

path = sys.argv[1] if len(sys.argv) > 1 else "wave.vcd"
with open(path) as f:
    lines = f.readlines()

# Header runs until $enddefinitions; the wrapper is the first scope in it and
# its matching $upscope is the last one before that marker.
end = next(i for i, l in enumerate(lines) if l.lstrip().startswith("$enddefinitions"))
try:
    top = next(i for i in range(end)
               if lines[i].split()[:3] == ["$scope", "module", "TOP"])
except StopIteration:
    sys.exit(0)  # already stripped, or not a Verilator dump
close = max(i for i in range(top, end) if lines[i].lstrip().startswith("$upscope"))

del lines[close]
del lines[top]
with open(path, "w") as f:
    f.writelines(lines)
