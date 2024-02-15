## Generate iDMA with AXIS support  (Terminal)
```
make eth-gen
```
## Update iDMA dependency
```
change target name "test" into "idma_test" to exclude idma test from compilation as idma tb is currently bugged (to-do)
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