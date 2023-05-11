#!/bin/bash

input_file=rom.txt
output_file=zen-x.srcs/sources_1/rom.coe

echo "process '$input_file' to '$output_file'"

echo "memory_initialization_radix=16;" > "$output_file"
echo -n "memory_initialization_vector=" >> "$output_file"
grep -v "^#" "$input_file" | tr -s ' ' '\n' | tr -d '\r' | sed '/^\s*$/d' | paste -sd ' ' >> "$output_file"
echo ";" >> "$output_file"
