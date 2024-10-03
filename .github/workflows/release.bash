#!/bin/bash

VERSION=$(grep -oP '(?<=\.version = ")[^"]*' build.zig.zon)
if git rev-parse "v$VERSION" >/dev/null 2>&1; then
	echo "A tag v$VERSION already exists"
	exit 1
fi

exit 0
