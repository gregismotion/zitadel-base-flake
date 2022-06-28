#!/bin/sh
set -xeu

echo "Generating Statik (phase 0)..."

pushd ${ZITADEL_PATH}
go generate internal/ui/login/statik/generate.go
go generate internal/ui/login/static/generate.go
go generate internal/notification/statik/generate.go
go generate internal/statik/generate.go
popd

echo "Generated Statik (phase 0)."
