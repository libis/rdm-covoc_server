#!/usr/bin/env bash
[[ -f .env ]] && source .env

[[ -z "$SOLR_HOST" ]] && SOLR_HOST=http://index:8983
[[ -z "$SOLR_CONTAINER" ]] && SOLR_CONTAINER=rdm-index-1
[[ -z "$SOLR_INDEX_DIR" ]] && SOLR_INDEX_DIR=/var/solr/data

export SOLR_HOST
export SOLR_CONTAINER
export SOLR_INDEX_DIR
