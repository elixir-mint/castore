#!/bin/bash

if ! mix certdata --check-outdated; then
  git checkout outdated || git checkout -b outdated
  mix certdata
  git add .
  git commit -m "Update certificates"
  git push --set-upstream origin outdated

  if [[ $(gh pr list --base outdated) == "" ]]; then
    gh pr create --fill
  fi
fi
