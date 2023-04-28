#!/bin/bash

git config user.name "${GITHUB_ACTOR}"
git config user.email "${GITHUB_ACTOR}@users.noreply.github.com"
changed_version="$(git diff --name-only HEAD~1 HEAD -- VERSION)"

if [[ "${changed_version}" ]]; then
  echo "Publishing because the version changed since the last commit"

  git tag "v$(cat VERSION)"
  git push --tags

  mix hex.publish --yes
else
  echo "Not publishing since the version didn't change since last commit"
fi
