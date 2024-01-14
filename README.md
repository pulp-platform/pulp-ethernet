## Generate iDMA with AXIS support  (Terminal)
```
make -C /idma checkout pwd/ idma_hw_all IDMA_BACKEND_IDS?=rw_axi_rw_axis
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