#!/bin/sh

echo "zen-one"
cat zen-one.srcs/sources_1/new/*.v | grep -vE '^\s*$|^\s*//'| wc
echo "zen-one gzipped"
cat zen-one.srcs/sources_1/new/*.v | grep -vE '^\s*$|^\s*//' | gzip | wc

echo "zasm"
cat zasm | grep -vE '^\s*$|^\s*//' | wc
echo "zasm gzipped"
cat zasm | grep -vE '^\s*$|^\s*//' | gzip | wc
