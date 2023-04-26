#!/bin/bash

changed_version="$(git diff --name-only HEAD~1 HEAD -- VERSION)"

if [[ "${changed_version}" ]]; then
	echo "Publishing because the version changed since the last commit"
  mix hex.publish --yes
else
	echo "Not publishing since the version didn't change since last commit"
fi
