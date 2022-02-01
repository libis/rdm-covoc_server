#!/usr/bin/env bash
source $(dirname $0)/vars.sh

[[ $# -lt 2 ]] && echo "Usage: $0 <core name> <data_file>" && exit
CORE="$1"
DATA_FILE="$2"

[[ ! -f "$DATA_FILE" ]] && echo "Data file $DATA_FILE does not exist" && exit

echo "Indexing data from ${DATA_FILE} into ${CORE} ..."

bundle exec ruby ${CORE}/index_data.rb "$DATA_FILE"
