#!/usr/bin/env bash
source .env

CORE="$1"
[ "${CORE}" == "" ] && echo "Usage: ${0} <core name>" && exit

docker exec -it ${SOLR_CONTAINER} mkdir -p ${SOLR_INDEX_DIR}/${CORE}/data
docker exec -it ${SOLR_CONTAINER} cp -fr ./server/solr/configsets/_default/conf ${SOLR_INDEX_DIR}/${CORE}/conf

curl "${SOLR_HOST}/solr/admin/cores?action=CREATE&name=${CORE}&instanceDir=${SOLR_INDEX_DIR}/${CORE}&dataDir=${SOLR_INDEX_DIR}/${CORE}/data&config=conf/solrconfig.xml"

curl -X POST -H 'Content-type: application/json' -d @data/${CORE}/schema.json "${SOLR_HOST}/solr/${CORE}/schema"

ruby data/${CORE}/convert_data.rb aftap_lirias.csv

curl -X POST -H 'Content-type: application/json' -d @data.json "${SOLR_HOST}/solr/${CORE}/update?commit=true"
