#!/bin/bash

set -euo pipefail

docker build \
    -f docker/template.Dockerfile \
    -t template .
