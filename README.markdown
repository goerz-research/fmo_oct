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

## How to run

*   Create a runfolder (e.g. `mkdir r001`) and change to it
*   Create a config file using the python script
    `../scripts/generate_config.py` (and review it)
*   Create the dissipator using the python script
    `../scripts/generate_dissipator.py`
*   Go back to the parent folder and run the optimal control (`./fmo_oct r001`)
*   After the optimization finishes, you can run the program for the propagation
    (`./fmo_prop r001`)
