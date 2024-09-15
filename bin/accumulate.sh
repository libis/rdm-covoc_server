#!/usr/bin/env bash
[ -f .env ] && source .env

CORE="${CORE:-$1}"
DATA_FILES="${DATA_FILES:-$2}"
TARGET="${TARGET:-$3}"
START_DATA_FILE=${START_DATA_FILE:-$4}
[ -z "${CORE}" -o -z "${TARGET}" -o -z "${DATA_FILES}" ] && { echo "Usage: $0 <core> <data_files> <target>"; exit; }

echo "Combining data from ${DATA_FILES} into ${TARGET} $([ -z "${START_DATA_FILE}" ] || echo "starting from ${START_DATA_FILE} " )..."

bundle exec ruby ${CORE}/combine_data.rb "$DATA_FILES" "${TARGET}" "${START_DATA_FILE}"
