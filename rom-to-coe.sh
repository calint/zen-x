#!/bin/bash

# generates the 'coe' file for BlockROM from 'rom.txt'
#  refresh the ip by validating and saving after changes in 'rom.txt'

input_file=rom.txt
output_file=zen-x.srcs/sources_1/rom.coe

echo "process '$input_file' to '$output_file'"

echo "memory_initialization_radix=16;" > "$output_file"
echo -n "memory_initialization_vector=" >> "$output_file"
grep -v "^#" "$input_file" | tr -s ' ' | tr -d '\r' | sed '/^\s*$/d' | paste -sd ' ' >> "$output_file"
echo ";" >> "$output_file"
