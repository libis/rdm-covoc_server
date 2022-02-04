#!/usr/bin/env bash
[ -f .env ] && source .env

CORE="${CORE:-$1}"
[ -z "$CORE" ] && { echo "Usage: $0 <core name>"; exit; }
[ -z "$SOLR_HOST" ] && { echo "ERROR: 'SOLR_HOST' needs to be set."; exit; }
[ -z "$INDEX_DATA_DIR" ] && { echo "ERROR: 'INDEX_DATA_DIR' needs to be set."; exit; }

echo "Creating ${CORE} index ..."

mkdir -p ${INDEX_DATA_DIR}/${CORE}/data
cp -fr ${INDEX_DATA_DIR}/configsets/_default/conf ${INDEX_DATA_DIR}/${CORE}/conf
echo '' >> ${INDEX_DATA_DIR}/${CORE}/conf/solrconfig.xml
sed -i "/<initParams/e cat ${CORE}/autocomplete.xml" ${INDEX_DATA_DIR}/${CORE}/conf/solrconfig.xml

R=$(curl -s "${SOLR_HOST}/solr/admin/cores?action=CREATE&name=${CORE}&instanceDir=/var/solr/data/${CORE}&dataDir=/var/solr/data/${CORE}/data&config=conf/solrconfig.xml")
[ "$(echo "$R" | jq ".responseHeader.status")" = "0" ] || { echo "ERROR: $(echo "$R" | jq ".error.trace" | head -1)"; exit; }

echo "Creating ${CORE} schema ..."

R=$(curl -s -X POST -H 'Content-type: application/json' -d @${CORE}/schema.json "${SOLR_HOST}/solr/${CORE}/schema")
[ "$(echo "$R" | jq ".responseHeader.status")" = "0" ] || { echo "ERROR: $(echo "$R" | jq ".error.trace" | head -1)"; exit; }

echo "Reloading ${CORE} index ..."

R=$(curl -s "${SOLR_HOST}/solr/admin/cores?action=RELOAD&core=${CORE}")
[ "$(echo "$R" | jq ".responseHeader.status")" = "0" ] || { echo "ERROR: $(echo "$R" | jq ".error.trace" | head -1)"; exit; }
