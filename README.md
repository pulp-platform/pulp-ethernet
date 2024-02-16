# PULP Ethernet

`pulp-ethernet` is developed as part of the PULP project, a joint effort between
ETH Zurich and the University of Bologna. It offers synthesizable Ethernet IP
that is technology- and FPGA-agnostic.

This is adapted from:
* LowRISC [`ariane-ethernet`](https://github.com/lowRISC/ariane-ethernet) GHz
  Ethernet top-level for Genesys II board, `master` branch (`ff9710f0`);
* Alex Forencich's
  [`verilog-ethernet`](https://github.com/alexforencich/verilog-ethernet)
  components for various FPGA boards; in particular, the RGMII GHz Ethernet MAC.

Where possible, original source files from the abovementioned sources have been
used.

`pulp-ethernet` is intended for use with https://github.com/pulp-platform/ariane
(a RISCV Linux-capable soft core).

## Generate iDMA with AXIS support  (Terminal)

```
make eth-gen
```

## Compile (Questa)

```
make eth-hw-build
```

## Simulate (Questa)
```
make eth-hw-sim
```

### Debugging

Per default, Questasim compilation is performance-optimised and simulation
logging is disabled. To enable full visibility, logging, and the Questa GUI, set
`DEBUG=1` when executing the steps above.

## Address map:

```
0x800 : mac_address[31:0]
0x808 : {irq_en,promiscuous,spare,loopback,cooked,mac_address[47:32]}
0x810 : tx_enable_dly <= 10; tx_packet_length <= core_lsu_wdata;
0x818 : tx_enable_dly <= 0; tx_packet_length <= 0;
0x820 : lastbuf
0x828 : firstbuf
```

## Linux drivers

Drivers can be found in the `driver/` folder. Patch to `cva6-sdk` is found
[here](https://github.com/openhwgroup/cva6-sdk/blob/master/linux_patch/0001-Incorporate-lowrisc-drivers-for-latest-kernel-releas.patch).

## License

Unless specified otherwise in the respective file headers, all code checked into
this repository is made available under a permissive license. All original
hardware sources and tool scripts are licensed under the Solderpad Hardware
License 0.51 (see `LICENSE`). All software sources are licensed under Apache
2.0. Third-party sources come with their own license (see `LICENSE.Forencich`).
