#!/usr/bin/env bash
[ -f .env ] && source .env

CORE="${CORE:-$1}"
DATA_FILE="${DATA_FILE:-$2}"
[ -z "${CORE}" -o -z "${DATA_FILE}" ] && { echo "Usage: $0 <core name> <data_file>"; exit; }
[ -z "$SOLR_HOST" ] && { echo "ERROR: 'SOLR_HOST' needs to be set."; exit; }
[ -f "$DATA_FILE" ] || { echo "Data file $DATA_FILE does not exist"; exit; }

echo "Indexing data from ${DATA_FILE} into ${CORE} ..."

bundle exec ruby ${CORE}/index_data.rb "$DATA_FILE" "${CORE}"

echo "Reloading ${CORE} index ..."

R=$(curl -s "${SOLR_HOST}/solr/admin/cores?action=RELOAD&core=${CORE}")
[ "$(echo "$R" | jq ".responseHeader.status")" = "0" ] || { echo "ERROR: $(echo "$R" | jq ".error.trace" | head -1)"; exit; }
