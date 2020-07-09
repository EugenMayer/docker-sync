# Setting up docs generator locally

To re-generate the docs on your local machine, simply follow the commands below.

## Docker based
Using docker, you will not need any local dependencies
from the docker-sync repo

```shell

docker run -p 8000:8000 -t -v "$(pwd)/docs":/web dldl/sphinx-server
```

Now you can connecto to http://localhost:8000 and browse the docs

If you change the docs in the source, it will be automatically regenerated and reloaded in the browser


## Without docker
Or of you want to run it locally you will need to install all the dependencies

```shell
# Install required dependencies
pip install sphinx sphinx-autobuild sphinx_rtd_theme
```

```shell
# Spins up the worker that will watch and re-generate the docs when changed
make livehtml
```

Navigate to `http://localhost:8000`. You'll see the latest docs there.

The pages will re-generate and reload itself when a file is changed.
