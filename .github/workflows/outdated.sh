#!/bin/bash

git config user.name "GitHub Actions"
git config user.email "actions@users.noreply.github.com"
git checkout outdated || git checkout -b outdated

if ! mix certdata --check-outdated; then
  mix certdata
  git add .
  git commit -m "Update certificates"
  git push --set-upstream origin outdated

  if [[ $(gh pr list --base outdated) == "" ]]; then
    gh pr create --fill
  fi
fi
