#!/bin/bash

# Assume package name == repository name
package="${GITHUB_REPOSITORY#*/}"

git config user.name "${GITHUB_ACTOR}"
git config user.email "${GITHUB_ACTOR}@users.noreply.github.com"

if [ $(git tag -l "v$(cat VERSION)") ]; then
  echo "NOT TAGGING"
else
  echo "TAGGING"
  git tag "v$(cat VERSION)"
  git push --tags
fi

if mix hex.info $package "$(cat VERSION)"; then
  echo "NOT PUBLISHING"
else
  echo "PUBLISHING"
  mix hex.publish --yes
fi
