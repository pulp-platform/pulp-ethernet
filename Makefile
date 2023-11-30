# Copyright 2023 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0

# Author: Alessandro Ottaviano <aottaviano@iis.ee.ethz.ch>

ETH_ROOT ?= $(shell pwd)
BENDER	 ?= bender -d $(ETH_ROOT)

clean:
	rm -rf .bender
	rm -f bender
	rm -f Bender.lock

include eth.mk
