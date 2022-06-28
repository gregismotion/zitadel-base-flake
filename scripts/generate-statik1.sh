#!/bin/sh
set -xeu

echo "Generating Statik (phase 1)..."

pushd ${ZITADEL_PATH}
go generate openapi/statik/generate.go
popd

echo "Generated Statik (phase 1)."
