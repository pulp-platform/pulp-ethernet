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
TBENCH ?= eth_tb
DUT    ?= eth_idma_wrap

# Design and simulation variables
ETH_ROOT      ?= $(shell $(BENDER) path fe-ethernet)
ETH_VSIM_DIR  := $(ETH_ROOT)/target/sim/vsim

IDMA_ROOT     ?= $(shell $(BENDER) path idma)

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

########
# Deps #
########

eth-checkout:
	$(BENDER) checkout
	touch Bender.lock

include $(IDMA_ROOT)/idma.mk

######################
# Nonfree components #
######################

ETH_NONFREE_REMOTE ?= git@iis-git.ee.ethz.ch:pulp-restricted/pulp-ethernet-nonfree.git
ETH_NONFREE_COMMIT ?= 9a45a7c

eth-nonfree-init:
	git clone $(ETH_NONFREE_REMOTE) $(ETH_ROOT)/nonfree
	cd $(ETH_ROOT)/nonfree && git checkout $(ETH_NONFREE_COMMIT)

-include $(ETH_ROOT)/nonfree/nonfree.mk

##############
# HW GEN     #
##############

eth-idma-gen: eth-checkout
	make -C $(IDMA_ROOT) idma_hw_all

##############
# Simulation #
##############

# Questasim
$(ETH_ROOT)/target/sim/vsim/compile.eth.tcl: Bender.yml
	$(BENDER) script vsim -t rtl -t test -t sim \
	--vlog-arg="-svinputport=compat" \
	--vlog-arg="-override_timescale 1ns/1ps" \
	--vlog-arg="-suppress 2583" > $@
	echo 'vopt $(VOPT_FLAGS) $(TBENCH) -o $(TBENCH)_opt' >> $@

eth-vsim-sim-build: eth-sim-init
	cd $(ETH_VSIM_DIR) && $(QUESTA) vsim -c -do "quit -code [source $(ETH_ROOT)/target/sim/vsim/compile.eth.tcl]"

eth-vsim-sim-run:
	cd $(ETH_VSIM_DIR) && $(QUESTA) vsim $(VSIM_FLAGS) -do \
		"set TESTBENCH $(TBENCH); \
		 set VSIM_FLAGS \"$(VSIM_FLAGS)\"; \
		 source $(ETH_ROOT)/target/sim/vsim/start.eth.tcl ; \
		 $(RUN_AND_EXIT)"

eth-vsim-sim-clean:
	cd $(ETH_VSIM_DIR) && rm -rf work transcript

# Global targets

eth-sim-init: $(ETH_ROOT)/target/sim/vsim/compile.eth.tcl
eth-sim-build: eth-vsim-sim-build
eth-sim-clean: eth-vsim-sim-clean

#################################
# Phonies (KEEP AT END OF FILE) #
#################################

.PHONY: eth-all eth-nonfree-init eth-checkout eth-idma-gen eth-sim-init eth-sim-build eth-sim-clean eth-vsim-sim-build eth-vsim-sim-clean eth-vsim-sim-run
