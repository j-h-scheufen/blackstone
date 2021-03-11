#!/usr/bin/env bash

version=$(git describe --tags)
version=${version#v}
# Make semver compliant by dot-separating the <prerelease> trailer
version="${version%-*}.${version##*-}"
echo "$version"

