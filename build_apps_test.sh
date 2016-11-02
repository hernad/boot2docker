#!/bin/bash

docker build -f Dockerfile.apps.test . --build-arg DOCKER_PROXY=172.17.0.2  -t greenbox_apps_test

echo -e
echo  "------------------------------------------"
echo "test apps.test image-a:"
echo "docker run --rm -ti greenbox_apps_test bash"
echo -e
