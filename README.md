## Register Configuration for DMA Operation
### TX (Transmit) Path:
- Set ```src_addr```: Configure the source address for the data transfer.
- Set ```dst_addr```: Specify the destination address for the data transfer.
- Set ```length```: Define the length of the data to be transferred.
- Set ```src_protocol```: Select the protocol used by the source for data transfer.
- Set ```dst_protocol```: Set the protocol for the destination.
- Check ```req_ready```: Request Ready: Ensure the read request is ready before trigger the transfer.
- Set ```req_valid```: Assert req_valid to initiate the data transfer.
- Check ```rsp_valid```: Wait for rsp_valid to confirm that the data transfer has been successfully completed.
### RX (Receive) Path:
- Wait for RX IRQ: Once the receive interrupt (rx_irq) is raised, confirm that DMA is ready to proceed with configuration.
- Check ```dma_rx_en```: Ensure the length of the received data is ready.
- Set ```src_addr```: Configure the source address for the receive operation.
- Set ```dst_addr```: Specify the destination address for the data to be stored.
- Set ```src_protocol```: Define the protocol used by the data source.
- Set ```dst_protocol```: Configure the protocol for the destination.
- Check ```req_ready```: Ensure the DMA's request is ready before proceeding.
- Set ```req_valid```: Assert req_valid to initiate data reception.
- Check ```rsp_valid```: Monitor rsp_valid to confirm that the data movement is complete.

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

## registers

Please refer gen/eth_idma_reg.hjson for a more detailed register bitfield definitions.

| Name         | Bits | SW Access | HW Access | HWQE Access | Default Value | Offset | Comment |
|--------------|------|-----------|-----------|-------------|---------------|--------|---------|
| low_addr   | 32   | rw        | hro       | 0           | 32'h00890702             | 0x0    | lower 4 bytes of the devices MAC address |
| machi   | 32   | rw        | hro       | 0           | 32'h00002301             | 0x4    | upper 2 bytes of the devices MAC address, cooked, loopback, promiscuous, irq_en|
| mdio       | 32   | rw        | hrw       | 0           | 0             | 0x8    | mdio control register |
| tx_busy       | 32   | ro        | hwo       | 0           | 0             | 0xc    | TX busy transmitting packets |
| tx_fcs       | 32    | ro        | hwo       | 0           | 0             | 0x10   | TX frame check register |
| rx_fcs       | 32    | ro        | hwo       | 0           | 0             | 0x14   | RX frame check register |
| rsr       | 32    | ro        | hwo       | 0           | 0             | 0x18   | receive status register, rx complete, rx interrupt |
| src_addr     | 32   | rw        | hro       | 0           | 0             | 0x1c   | iDMA Source Address |
| dst_addr     | 32   | rw        | hro       | 0           | 0             | 0x20   | iDMA Desitnation Address |
| length       | 32   | rw        | hrw       | 0           | 0             | 0x24   | iDMA Number of bytes to move |
| src_protocol | 3    | rw        | hro       | 0           | 0             | 0x28   | iDMA source protocol |
| dst_protocol | 3    | rw        | hro       | 0           | 0             | 0x2c   | iDMA desination protocol |
| axi_id       | 1    | rw        | hrw       | 0           | 0             | 0x30   | iDMA transaction ID |
| opt_src      | 18   | rw        | hro       | 0           | 0             | 0x34   | iDMA source options |
| opt_dst      | 18   | rw        | hro       | 0           | 0             | 0x38   | iDMA destination options |
| beo          | 10   | rw        | hro       | 0           | 0             | 0x3c   | iDMA backend options |
| last         | 1    | rw        | hrw       | 0           | 0             | 0x40   | iDMA last transfer |
| req_valid    | 1    | rw        | hrw       | 0           | 0             | 0x44   | iDMA request valid, handshake signal asserted by user for data movement request |
| req_ready    | 1    | ro        | hrw       | 0           | 0             | 0x48   | iDMA request ready, handshake signal asserted by hw that indicates iDMA is ready to accept request |
| rsp_ready    | 1    | rw        | hrw       | 0           | 0             | 0x4c   | iDMA response ready, handshake signal asserted by user so that iDMA will start moving data |
| rsp_valid    | 1    | ro        | hrw       | 0           | 0             | 0x50   | iDMA response valid, handshake signal asserted by hw so that iDMA has finished data moving |
| dma_rx_en    | 1    | ro        | hwo       | 0           | 0             | 0x54   | indicates dma can be configured now in RX case|
