#/usr/bin/env bash

GENERATED_DATA="$2/generated_data"

if ! grep -q "flymake" "$GENERATED_DATA" ; then
    exit 1
fi
