#!/bin/sh
ARCH=$1
docker run --rm --privileged \
  -v ~/.docker:/root/.docker \
  -v /run/docker.sock:/run/docker.sock:rw \
  -v $(pwd)/silabs-multiprotocol-ember:/data homeassistant/amd64-builder --${ARCH} -t /data --self-cache
