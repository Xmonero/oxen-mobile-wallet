#!/bin/bash

if [ "$#" -ne 1 ] || [[ "$1" != http* ]]; then
    echo "Usage: $0 URL -- download and extract an quenero-core android-deps package (typically from https://quenero.tech)" >&2
    exit 1
fi

if ! [ -d quenero_coin/ios/External/android/quenero ]; then
    echo "This script needs to be invoked from the quenero-wallet top-level project directory" >&2
    exit 1
fi

curl -sS "$1" | tar --strip-components=1 -C quenero_coin/ios/External/android/quenero/ -xJv
