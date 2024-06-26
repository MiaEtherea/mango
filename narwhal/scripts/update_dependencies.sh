#!/bin/bash
# Copyright (c) MangoNet Labs Ltd.
# SPDX-License-Identifier: Apache-2.0

# This script attempts to update the Narwhal pointer in Mgo
# It is expected to fail in cases 
set -e
set -eo pipefail

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
TOPLEVEL="${DIR}/../"
GREP=${GREP:=grep}

# Crutch for old bash versions
# Very minimal readarray implementation using read. 
readarray() {
	while IFS= read -r var; do
        MAPFILE+=("$var")
	done
}


# check for the presence of needed executables:
# - we use GNU grep in perl re mode
# - we use cargo-hakari
function check_gnu_grep() {
	GNUSTRING=$($GREP --version|head -n1| grep 'GNU grep')
	if [[ -z $GNUSTRING ]];
	then 
		echo "Could not find GNU grep. This requires GNU grep 3.7 with PCRE expressions"; exit 1
	else 
		return 0
	fi
}

function check_cargo_hakari() {
	cargo hakari --version > /dev/null 2>&1
	if [[ $? -ne 0 ]]; then
		echo "Could not find cargo hakari. Please install"; exit 1		
	else
		return 0
	fi
}

function latest_mi_revision() {
	MI_CHECKOUT=$(mktemp -d)
	cd "$MI_CHECKOUT"
	git clone --depth 1 https://github.com/MangoNetworkOs/mango-infra
	cd mango-infra
	git rev-parse HEAD
}

function current_mi_revision() {
	cd "$TOPLEVEL"
	readarray -t <<< "$(find ./ -iname '*.toml' -exec $GREP -oPie 'git = "https://github.com/[mM]ystenLabs/mango-infra(\.git)?", *rev *= *\"\K[0-9a-fA-F]+' '{}' \;)"
	watermark=${MAPFILE[0]}
	for i in "${MAPFILE[@]}"; do
	    if [[ "$watermark" != "$i" ]]; then
        	not_equal=true
	        break
	    fi
	done

	[[ -n "$not_equal" ]] && echo "Different values found for the current mango-infra revision in NW, aborting" && exit 1
	echo "$watermark"
}

# Check for tooling
check_gnu_grep
check_cargo_hakari

# Debug prints for mango-infra
CURRENT_MI=$(current_mi_revision)
LATEST_MI=$(latest_mi_revision)
if [[ "$CURRENT_MI" != "$LATEST_MI" ]]; then
	echo "About to replace $CURRENT_MI with $LATEST_MI as the mango-infra pointer in Narwhal"
else
	exit 0
fi

# Edit the source & run hakari
find ./ -iname "*.toml"  -execdir sed -i '' -re "s/$CURRENT_MI/$LATEST_MI/" '{}' \;
cargo hakari generate
