# Cachi2 playground

A simple shell script to perform a hermetic build using Cachi2 to prefetch the dependencies.

The script takes a git repo as the input param, and will clone, prefetch, inject project files,
and build it using buildah while cutting all network access.

A custom Dockerfile can also be used, and will be copied into the cloned source code folder.

## How to use

1. Edit the params in the `input.env` file
2. Run ./clone-and-build.sh
