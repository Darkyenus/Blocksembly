#!/bin/sh
cd "$(dirname "$0")"

#./build.sh && vvp -s target/blocksembly
./build.sh && vvp -n target/blocksembly
