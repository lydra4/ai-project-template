#!/bin/bash

docker build \
    -f docker/template.Dockerfile \
    -t template .
