#!/usr/bin/env bash
source .env

CORE="$1"
[ "${CORE}" == "" ] && echo "Usage: ${0} <core name>" && exit

DATA_FILE="$2"
[[ -z "$DATA_FILE" ]] && echo "Data file $DATA_FILE does not exist" && exit

echo "Creating ${CORE} index ..."

docker exec -it ${SOLR_CONTAINER} mkdir -p ${SOLR_INDEX_DIR}/${CORE}/data
docker exec -it ${SOLR_CONTAINER} cp -fr ./server/solr/configsets/_default/conf ${SOLR_INDEX_DIR}/${CORE}/conf
docker cp ${CORE}/solrconfig.xml ${SOLR_CONTAINER}:${SOLR_INDEX_DIR}/${CORE}/conf/solrconfig.xml

R=$(curl -s "${SOLR_HOST}/solr/admin/cores?action=CREATE&name=${CORE}&instanceDir=${SOLR_INDEX_DIR}/${CORE}&dataDir=${SOLR_INDEX_DIR}/${CORE}/data&config=conf/solrconfig.xml")
[ "$(echo "$R" | jq ".responseHeader.status")" = "0" ] || { echo "ERROR: $(echo "$R" | jq ".error.trace" | head -1)"; exit; }

echo "Creating ${CORE} schema ..."

R=$(curl -s -X POST -H 'Content-type: application/json' -d @${CORE}/schema.json "${SOLR_HOST}/solr/${CORE}/schema")
[ "$(echo "$R" | jq ".responseHeader.status")" = "0" ] || { echo "ERROR: $(echo "$R" | jq ".error.trace" | head -1)"; exit; }

echo "Converting ${CORE} data from ${DATA_FILE} ..."

ruby ${CORE}/convert_data.rb "$DATA_FILE" "${CORE}.json"

echo "Indexing ${CORE} data ..."

R=$(curl -s -X POST -H 'Content-type: application/json' -d "@${CORE}.json" "${SOLR_HOST}/solr/${CORE}/update?commit=true")
[ "$(echo "$R" | jq ".responseHeader.status")" = "0" ] || { echo "ERROR: $(echo "$R" | jq ".error.trace" | head -1)"; exit; }
