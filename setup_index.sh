#!/usr/bin/env bash
source .env

CORE="$1"
[ "${CORE}" == "" ] && echo "Usage: ${0} <core name>" && exit

DATA_FILE="$2"
[[ -z "$DATA_FILE" ]] && echo "Data file $DATA_FILE does not exist" && exit

echo "Creating ${CORE} index ..."

docker exec -it ${SOLR_CONTAINER} mkdir -p ${SOLR_INDEX_DIR}/${CORE}/data
docker exec -it ${SOLR_CONTAINER} cp -fr ./server/solr/configsets/_default/conf ${SOLR_INDEX_DIR}/${CORE}/conf

curl "${SOLR_HOST}/solr/admin/cores?action=CREATE&name=${CORE}&instanceDir=${SOLR_INDEX_DIR}/${CORE}&dataDir=${SOLR_INDEX_DIR}/${CORE}/data&config=conf/solrconfig.xml"

echo "Creating ${CORE} schema ..."

curl -X POST -H 'Content-type: application/json' -d @${CORE}/schema.json "${SOLR_HOST}/solr/${CORE}/schema"

echo "Converting ${CORE} data from ${DATA_FILE} ..."

ruby ${CORE}/convert_data.rb "$DATA_FILE" "${CORE}.json"

echo "Indexing ${CORE} data ..."

curl -X POST -H 'Content-type: application/json' -d "@${CORE}.json" "${SOLR_HOST}/solr/${CORE}/update?commit=true"
