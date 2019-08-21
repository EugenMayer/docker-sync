# Setting up docs generator locally

To re-generate the docs on your local machine, simply follow the commands below.

```shell
# Install required dependencies
pip install sphinx sphinx-autobuild sphinx_rtd_theme

# Spins up the worker that will watch and re-generate the docs when changed
make livehtml
```

Navigate to `http://localhost:8000`. You'll see the latest docs there.
The pages will re-generate and reload itself when a file is changed.
