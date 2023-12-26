#!/usr/bin/env bash

rm -r work/

./scripts/compile_vsim.sh

questa-2019.3 vsim eth_idma_tb -t 1ns -coverage -voptargs="+acc +cover=bcesfx"
