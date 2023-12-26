#!/bin/bash

set -e

[ ! -z "$SYNTHESIS_DIR" ] || SYNTHESIS_DIR=../..

echo 'set ROOT [file normalize [file dirname [info script]]/../../sourcecode/fe-ethernet/]' > $SYNTHESIS_DIR/synopsys/scripts/analyze_ethernet.tcl
bender script synopsys -t rtl -t synthesis -t asic | grep -v "set ROOT" >> $SYNTHESIS_DIR/synopsys/scripts/analyze_ethernet.tcl