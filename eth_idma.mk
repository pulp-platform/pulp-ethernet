# Copyright 2023 ETH Zurich
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# Author: Alessandro Ottaviano <aottaviano@iis.ee.ethz.ch>

BENDER ?= bender
QUESTA ?= questa-2022.3
TBENCH ?= eth_idma_tb
DUT    ?= eth_idma_wrap

IDMA_BACKEND_IDS ?=rw_axi_rw_axis
DMA_ROOT    ?= $(shell $(BENDER) path idma)

# Design and simulation variables
ETH_ROOT      ?= $(shell $(BENDER) path fe-ethernet)

QUESTA_FLAGS := -permissive -suppress 3009 -suppress 8386 -error 7 +UVM_NO_RELNOTES
#QUESTA_FLAGS :=
ifdef DEBUG
	VOPT_FLAGS := $(QUESTA_FLAGS) +acc
	VSIM_FLAGS := $(QUESTA_FLAGS)
	RUN_AND_EXIT := log -r /*; run -all
else
	VOPT_FLAGS := $(QUESTA_FLAGS) -O5 +acc=p+$(TBENCH). +noacc=p+$(DUT).
	VSIM_FLAGS := $(QUESTA_FLAGS) -c
	RUN_AND_EXIT := run -all; exit
endif

######################
# Nonfree components #
######################

ETH_NONFREE_REMOTE ?= git@iis-git.ee.ethz.ch:pulp-restricted/pulp-ethernet-nonfree.git
ETH_NONFREE_COMMIT ?= cd8dcd3

eth-nonfree-init:
	git clone $(ETH_NONFREE_REMOTE) $(ETH_ROOT)/nonfree
	cd $(ETH_ROOT)/nonfree && git checkout $(ETH_NONFREE_COMMIT)

-include $(ETH_ROOT)/nonfree/nonfree.mk

##############
# HW GEN     #
##############  

eth-gen:
	make -C $(DMA_ROOT) idma_hw_all IDMA_BACKEND_IDS=$(IDMA_BACKEND_IDS)

##############
# Simulation #
##############                            

$(ETH_ROOT)/target/sim/vsim/compile.eth.tcl: Bender.yml
	$(BENDER) script vsim -t test -t rtl \
	--vlog-arg="-svinputport=compat" \
	--vlog-arg="-override_timescale 1ns/1ps" \
	--vlog-arg="-suppress 2583" > $@
	echo 'vopt $(VOPT_FLAGS) $(TBENCH) -o $(TBENCH)_opt' >> $@

eth-sim-init: $(ETH_ROOT)/target/sim/vsim/compile.eth.tcl

eth-hw-build: eth-sim-init
	$(QUESTA) vsim -c -do "quit -code [source $(ETH_ROOT)/target/sim/vsim/compile.eth.tcl]"

eth-hw-sim:
	$(QUESTA) vsim $(VSIM_FLAGS) -do \
		"set TESTBENCH $(TBENCH); \
		 set VSIM_FLAGS \"$(VSIM_FLAGS)\"; \
		 source $(ETH_ROOT)/target/sim/vsim/start.eth.tcl ; \
		 $(RUN_AND_EXIT)"

#################################
# Phonies (KEEP AT END OF FILE) #
#################################

.PHONY: eth-all eth-nonfree-init eth-sim-init eth-hw-build eth-hw-sim
