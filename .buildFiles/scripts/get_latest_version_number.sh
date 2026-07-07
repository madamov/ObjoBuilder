#!/usr/bin/env bash

VERSION=$(
  curl -fsSL https://objo.dev/download |
  grep -oE 'Latest version:[[:space:]]*[0-9]+\.[0-9]+\.[0-9]+' |
  head -n1 |
  sed -E 's/Latest version:[[:space:]]*//'
)

echo "$VERSION"
