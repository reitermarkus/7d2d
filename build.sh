#!/usr/bin/env bash

set -euo pipefail

versions=(alpha19.2 alpha18.4 alpha17.4)

for version in "${versions[@]}"; do
  docker build --build-arg "VERSION=${version}" -t "reitermarkus/7d2d:${version}" .
done

for version in "${versions[@]}"; do
  docker push "reitermarkus/7d2d:${version}"
done
