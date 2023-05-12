#!/bin/sh

echo "wc source:"
cat zen-x.srcs/sources_1/new/* | grep -v '^[[:space:]]*$'| wc
echo "wc gzipped source:"
cat zen-x.srcs/sources_1/new/* | grep -v '^[[:space:]]*$' | gzip | wc
