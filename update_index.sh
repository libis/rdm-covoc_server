#!/usr/bin/env bash
source .env

CORE="$1"
[ "${CORE}" == "" ] && echo "Usage: ${0} <core name>" && exit

DATA_FILE="$2"
[[ -z "$DATA_FILE" ]] && echo "Data file $DATA_FILE does not exist" && exit

echo "Converting ${CORE} data from ${DATA_FILE} ..."

ruby ${CORE}/convert_data.rb "$DATA_FILE" "${CORE}.json"

echo "Indexing ${CORE} data ..."

R=$(curl -s -X POST -H 'Content-type: application/json' -d "@${CORE}.json" "${SOLR_HOST}/solr/${CORE}/update?commit=true")
[ "$(echo "$R" | jq ".responseHeader.status")" = "0" ] || { echo "ERROR: $(echo "$R" | jq ".error.trace" | head -1)"; exit; }
