#!/usr/bin/env bash
[ -f .env ] && source .env

CORE="${CORE:-$1}"
BACKUP_DIR="${BACKUP_DIR:-$2}"
[ -z "${CORE}" -o -z "${BACKUP_DIR}" ] && { echo "Usage: $0 <core name> <backup_dir>"; exit; }
[ -z "$SOLR_HOST" ] && { echo "ERROR: 'SOLR_HOST' needs to be set."; exit; }
[ -d "$BACKUP_DIR" ] || { echo "Backup dir $BACKUP_DIR does not exist"; exit; }

echo "Restoring data from ${BACKUP_DIR} into ${CORE} ..."

bundle exec ruby ${CORE}/load_backup.rb "$BACKUP_DIR" "$CORE"

echo "Reloading ${CORE} index ..."

R=$(curl -s "${SOLR_HOST}/solr/admin/cores?action=RELOAD&core=${CORE}")
[ "$(echo "$R" | jq ".responseHeader.status")" = "0" ] || { echo "ERROR: $(echo "$R" | jq ".error.trace" | head -1)"; exit; }
