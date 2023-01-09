#!/usr/bin/env bash

# Print usage message and exit if no arguments are passed
if [ $# -lt 3 ]; then
  echo "Usage: write_secrets.sh APP_NAME ENVIRONMENT_NAME SECRETS_FILE"
  exit 1
fi

# Parse arguments
APP_NAME=$1
ENVIRONMENT_NAME=$2
SECRETS_FILE=$3

# Check if SECRETS_FILE exists
if [ ! -f "$SECRETS_FILE" ]; then
  echo "Error: Secrets file not found: $SECRETS_FILE"
  exit 1
fi

# Read SECRETS_FILE line by line and write secrets to AWS Secrets Manager
while IFS= read -r line; do
  # Split line on first colon and trim whitespace
  IFS=':' read -ra parts <<< "$line"
  key=$(echo "${parts[0]}" | xargs)
  value=$(echo "$line" | sed "s/^$key: //" | xargs)
  
  # Check if secret already exists
  if aws secretsmanager get-secret-value --secret-id "$APP_NAME/$ENVIRONMENT_NAME/$key" &> /dev/null; then
    # Secret already exists, update the value
    aws secretsmanager put-secret-value --secret-id "$APP_NAME/$ENVIRONMENT_NAME/$key" --secret-string "$value"
  else
    # Secret does not exist, create it
    aws secretsmanager create-secret --name "$APP_NAME/$ENVIRONMENT_NAME/$key" --secret-string "$value"
  fi
done < "$SECRETS_FILE"

