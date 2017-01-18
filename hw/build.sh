#!/bin/sh
cd "$(dirname "$0")"

#iverilog -Wall -pfileline=1 -o target/blocksembly src/blocpu_simulation_runner.v src/blocpu_core.v
iverilog -Wall -o target/blocksembly src/blocpu_simulation_runner.v src/blocpu_core.v

