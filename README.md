## Generate iDMA with AXIS support  (Terminal)
```
make -C /your-idma-checkout-pwd/ idma_hw_all IDMA_BACKEND_IDS?=rw_axi_rw_axis
```
## Update iDMA dependency
Firstly, change target name "test" into "idma_test" to exclude idma test from compilation as idma tb is currently bugged (to-do)

Secondly, add following into tartget "rtl"
```
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