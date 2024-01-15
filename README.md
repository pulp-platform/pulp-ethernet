## Generate iDMA with AXIS support  (Terminal)
```
make -C /idma checkout pwd/ idma_hw_all IDMA_BACKEND_IDS?=rw_axi_rw_axis
```
## Update iDMA dependency
```
change name of tartget "test" to "idma_test" as it seems some tbs are still bugged
add following into tartget "rtl"
 - src/idma_pkg.sv
 - target/rtl/idma_legalizer_rw_axi_rw_axis.sv
 - target/rtl/idma_transport_layer_rw_axi_rw_axis.sv
 - target/rtl/idma_backend_rw_axi_rw_axis.sv
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