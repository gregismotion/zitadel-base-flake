#!/bin/sh

# create gopath
mkdir gopath
mkdir gopath/src
mkdir gopath/bin
mkdir gopath/pkg
export GOPATH=./gopath

export SRC_PATH=${GOPATH}/src/github.com/zitadel/zitadel
mkdir -p ${SRC_PATH}
pushd ${SRC_PATH}
cp -r ${zitadel-src}/* .
popd

# TODO: create dep flakes too
#export PATH=${GOPATH}/src/github.com/grpc-ecosystem/grpc-gateway/protoc-gen-grpc-gateway/:${GOPATH}/src/github.com/grpc-ecosystem/grpc-gateway/protoc-gen-openapiv2/:./internal/protoc/protoc-gen-authoption/:${GOPATH}/src/github.com/envoyproxy/protoc-gen-validate/:${PATH}
