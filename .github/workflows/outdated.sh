#!/bin/bash

function bump_version {
  awk -F. '{printf("%d.%d.%d\n", $1, $2, $3+1) >"VERSION"}' VERSION
}

function check_pr {
  gh pr list --state open --label "outdated check"
}

git config user.name "${GITHUB_ACTOR}"
git config user.email "${GITHUB_ACTOR}@users.noreply.github.com"
git checkout outdated || git checkout -b outdated

if ! mix certdata --check-outdated; then
  mix certdata

  if [[ $(check_pr) == "" ]]; then
    bump_version
  fi

  git add .
  git commit -m "Update certificates"
  git push --set-upstream origin outdated

  if [[ $(check_pr) == "" ]]; then
    gh pr create --fill --label "outdated check"
  fi
fi
