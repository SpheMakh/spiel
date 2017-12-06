# Spiel

CWL version based on the simulation example from Stimela.

https://github.com/SpheMakh/Stimela/blob/master/examples/simulation_pipeline.py


# requirements

* virtualenv to bootstrap CWLrunner
* [Docker](https://www.docker.com/) if you want to run containers
* Ubuntu 16.04 with KERN-3 repository enabled if you dont want to use containers

To run the pipeline with the example dataset just run:
```bash
$ make
```

If you don't use docker but want to run everything outside the container:
```bash
$ make nodocker
```

If you want to try out toil run:
```bash
$ make toil
```o

[![graph](https://raw.githubusercontent.com/gijzelaerr/spiel/master/spiel.png)](https://view.commonwl.org/workflows/github.com/gijzelaerr/spiel/blob/master/spiel.cwl) 

