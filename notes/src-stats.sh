#!/bin/sh

echo "wc zen-x:"
cat zen-x.srcs/sources_1/new/* | grep -v '^[[:space:]]*$'| wc
echo "wc zen-x gzipped:"
cat zen-x.srcs/sources_1/new/* | grep -v '^[[:space:]]*$' | gzip | wc

echo "wc zasm:"
cat zasm | grep -v '^[[:space:]]*$'| wc
echo "wc gzipped zasm:"
cat zasm | grep -v '^[[:space:]]*$' | gzip | wc
