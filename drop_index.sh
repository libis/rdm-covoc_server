#!/usr/bin/env bash
source .env

CORE="$1"
[ "${CORE}" == "" ] && echo "Usage: ${0} <core name>" && exit

curl "${SOLR_HOST}/solr/admin/cores?action=UNLOAD&core=${CORE}&deleteIndex=true&deleteDataDir=true&deleteInstanceDir=true"
