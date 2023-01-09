#!/bin/bash

set -eu

function usage() {
    echo "Usage: delete_secrets.sh PREFIX"
}

if [[ $# -ne 1 ]]; then
    usage
    exit 1
fi

PREFIX=$1

# List secrets with the specified prefix
SECRETS=$(aws secretsmanager list-secrets --output json --max-results 100 --filters "$(jq -nc --arg p "$PREFIX" '[{Key: "name", Values: [$p]}]')")

# Extract secret names from the list
SECRET_NAMES=$(echo "$SECRETS" | jq -r '.SecretList[].Name')

echo "These secrets will be deleted:"
echo "$SECRET_NAMES"

read -p "Are you sure you want to delete these secrets? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Okay, bye!"
    exit 0
fi

# Delete each secret
while read -r SECRET_NAME; do
    aws secretsmanager delete-secret --secret-id "$SECRET_NAME"
done <<< "$SECRET_NAMES"

echo "Secrets deleted."

