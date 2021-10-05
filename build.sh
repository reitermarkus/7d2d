#!/usr/bin/env bash

set -euo pipefail

image='reitermarkus/7d2d'

docker build --cache-from "${image}" -t "${image}" .

if [[ "${1-}" == '--push' ]]; then
  docker push "${image}"
fi
