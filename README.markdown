# fmo_oct

Code for optimization of FMO complex transport

## Prerequisites

* `qdyn` library (Koch group, University of Kassel)

## Overview

compile with `make`.

Available programs:

*   `fmo_oct`: Starting from the pulse defined in the config file, run a Krotov
    optimization.
 
*   `fmo_prop`: Propagate the optimized pulse for analysis purpose. You may also
    propagate the guess pulse by specifying 'propagate_guess' in the config file
