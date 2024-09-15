#!/usr/bin/env bash
[ -f .env ] && source .env

CORE="${CORE:-$1}"
BACKUP_DIR="${BACKUP_DIR:-$2}"
[ -z "${CORE}" -o -z "${BACKUP_DIR}" ] && { echo "Usage: $0 <core name> <backup_dir>"; exit; }
[ -z "$SOLR_HOST" ] && { echo "ERROR: 'SOLR_HOST' needs to be set."; exit; }

echo "Backing up ${CORE} data to ${BACKUP_DIR} ..."

bundle exec ruby ${CORE}/save_backup.rb "$BACKUP_DIR" "${CORE}"
