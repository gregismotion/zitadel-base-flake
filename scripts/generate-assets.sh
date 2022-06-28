#!/bin/sh
set -xeu

echo "Generating assets..."

pushd ${ZITADEL_PATH}
mkdir -p docs/apis/assets/
go run internal/api/assets/generator/asset_generator.go -directory=internal/api/assets/generator/ -assets=docs/apis/assets/assets.md
popd

echo "Generated assets."
