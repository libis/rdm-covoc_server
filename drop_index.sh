#!/usr/bin/env bash
source $(dirname $0)/vars.sh

[[ -z "$1" ]] && echo "Usage: $0 <core name>" && exit
CORE="$1"

echo "Unloading and deleting ${CORE} index ..."
R=$(curl -s "${SOLR_HOST}/solr/admin/cores?action=UNLOAD&core=${CORE}&deleteIndex=true&deleteDataDir=true&deleteInstanceDir=true")

[ "$(echo "$R" | jq ".responseHeader.status")" = "0" ] || { echo "ERROR: $(echo "$R" | jq ".error.trace" | head -1)"; exit; }
