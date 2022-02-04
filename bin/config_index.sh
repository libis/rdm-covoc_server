#!/usr/bin/env bash
[ -f .env ] && source .env

CORE="${CORE:-$1}"
[ -z "$CORE" ] && { echo "Usage: $0 <core name>"; exit; }
[ -z "$SOLR_HOST" ] && { echo "ERROR: 'SOLR_HOST' needs to be set."; exit; }
[ -z "$INDEX_DATA_DIR" ] && { echo "ERROR: 'INDEX_DATA_DIR' needs to be set."; exit; }

echo "Updating ${CORE} solrconfig.xml ..."

cp ${INDEX_DATA_DIR}/configsets/_default/conf/solrconfig.xml ${INDEX_DATA_DIR}/${CORE}/conf/solrconfig.xml
echo '' >> ${INDEX_DATA_DIR}/${CORE}/conf/solrconfig.xml
sed -i "/<initParams/e cat ${CORE}/autocomplete.xml" ${INDEX_DATA_DIR}/${CORE}/conf/solrconfig.xml

echo "Reloading ${CORE} index ..."

R=$(curl -s "${SOLR_HOST}/solr/admin/cores?action=RELOAD&core=${CORE}")
[ "$(echo "$R" | jq ".responseHeader.status")" = "0" ] || { echo "ERROR: $(echo "$R" | jq ".error.trace" | head -1)"; exit; }
