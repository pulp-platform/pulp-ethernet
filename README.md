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
```
maclo_addr:   Lower 32 bit of the devices MAC address,
machi_mdio:   [15:0]upper 2 bytes of the devices MAC address, [16]promiscuous flag, [19:17]MDIO interface",
tx_irq:       Ethernet transmission done,TX interrupt,
src_addr:     Data source address,
dst_addr:     Data destination address,
length:       Number of data byte to be moved by iDMA,
src_protocol: iDMA source protocol,
dst_protocol: iDMA destination protocol,
req_valid:    Validate data move request to iDMA,
req_ready:    iDMA is ready to accept request,
rsp_ready:    iDMA is ready to move data,
rsp_valid:    iDMA has moved all the requested data,
rx_irq:       Ethernet starts receiving packets, RX interrupt
        
        ```