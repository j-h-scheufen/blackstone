#!/usr/bin/env bash

version=$(git describe --tags)
version=${version#v}
# Make semver compliant by dot-separating the <prerelease> trailer
main_version="${version%-*}"
trailer="${version##*-}"

if [[ "$main_version" != "$trailer" ]]; then
  version="$main_version.$trailer"
fi

echo "$version"

