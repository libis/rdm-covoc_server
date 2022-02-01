#!/usr/bin/env bash
source $(dirname $0)/vars.sh

[[ -z "$1" ]] && echo "Usage: $0 <core name>" && exit
CORE="$1"

echo "Creating ${CORE} index ..."

docker exec -it ${SOLR_CONTAINER} mkdir -p ${SOLR_INDEX_DIR}/${CORE}/data
docker exec -it ${SOLR_CONTAINER} cp -fr ./server/solr/configsets/_default/conf ${SOLR_INDEX_DIR}/${CORE}/conf
docker cp ${CORE}/solrconfig.xml ${SOLR_CONTAINER}:${SOLR_INDEX_DIR}/${CORE}/conf/solrconfig.xml

R=$(curl -s "${SOLR_HOST}/solr/admin/cores?action=CREATE&name=${CORE}&instanceDir=${SOLR_INDEX_DIR}/${CORE}&dataDir=${SOLR_INDEX_DIR}/${CORE}/data&config=conf/solrconfig.xml")
[ "$(echo "$R" | jq ".responseHeader.status")" = "0" ] || { echo "ERROR: $(echo "$R" | jq ".error.trace" | head -1)"; exit; }

echo "Creating ${CORE} schema ..."

R=$(curl -s -X POST -H 'Content-type: application/json' -d @${CORE}/schema.json "${SOLR_HOST}/solr/${CORE}/schema")
[ "$(echo "$R" | jq ".responseHeader.status")" = "0" ] || { echo "ERROR: $(echo "$R" | jq ".error.trace" | head -1)"; exit; }
