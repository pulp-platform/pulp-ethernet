# Copyright 2023 ETH Zurich and University of Bologna.
# Solderpad Hardware License, Version 0.51, see LICENSE for details.
# SPDX-License-Identifier: SHL-0.51
#
# Alessandro Ottaviano <aottaviano@iis.ee.ethz.ch>

set flags ""
if {[info exists VSIM_FLAGS]}     { append flags "${VSIM_FLAGS}" }

eval "vsim ${TESTBENCH}_opt -coverage -t 1ns" ${flags}

set StdArithNoWarnings 1
set NumericStdNoWarnings 1
