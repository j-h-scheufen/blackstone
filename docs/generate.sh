#!/usr/bin/env bash

set -e
# Prerequisites
#npm config set unsafe-perm true # https://github.com/npm/uid-number/issues/3
pushd ./docs/generator
npm install
npm link sol2uml@1.1.10
export PATH=$(npm bin):$PATH
popd

# Create Blackstone Contracts Docs
mkdir -p docs/docdev
pushd contracts/src
# Generate UML diagrams for bundles
for bundle in *; do
    if [[ -d ${bundle} && ! -L ${bundle} && ! ${bundle} == "bin" ]]; then
        echo "Generating UML diagram for $bundle"
        sol2uml ./$bundle -o ../../docs/images/${bundle}-class-diagram.svg -d 0
    fi
done

# Workaround for broken burrow
mkdir -p $(awk '/binpath/ { print $2 }' < generate-devdocs.yaml)
burrow deploy generate-devdocs.yaml
popd

node docs/generator/docgen-contract.js docs/docdev > docs/smart_contracts.md

# Create Blackstone API Docs
apidoc \
  --config docs/generator \
  --input api/routes/ \
  --output docs/apidoc

apidocjs-markdown \
  --path docs/apidoc \
  --output docs/rest_api.md \
  --template docs/generator/apiDocTemplate.md
