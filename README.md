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