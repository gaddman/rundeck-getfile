#!/usr/bin/env bash

#####
# getfile.sh
# This script retrieves a file from a remote node.
# usage: getfile.sh
#
# Chris Gadd
# 2021-02-25
#####

set -e

SOURCE=$RD_CONFIG_SOURCE
DESTINATION=$RD_CONFIG_DESTINATION
PROTOCOL=$RD_CONFIG_PROTOCOL
HOST=$RD_NODE_HOSTNAME
PROJECT=$RD_JOB_PROJECT

# if no node username defined use job user
if [[ -n "${RD_NODE_USERNAME:-}" ]]; then
  USERNAME=$(echo $RD_NODE_USERNAME | sed "s/\${job.username}/$RD_JOB_USERNAME/")
else
  USERNAME="$RD_JOB_USERNAME"
fi

# Do some basic checks that the destination isn't anywhere stupid
REALDESTINATION=$(realpath $DESTINATION)
if [[ "$REALDESTINATION" =~ ^/etc/rundeck/ ]]; then
  echo "Invalid destination: $DESTINATION"
  exit 1
fi

# If the destination is a directory and doesn't exist, create it
if [[ "${DESTINATION:(-1)}" == "/" && ! -d "$DESTINATION" ]]; then
  mkdir -p "$DESTINATION"
fi

# password may come from storage or an option called 'password'
# key may come from storage
if [[ -n "${RD_SECUREOPTION_PASSWORD:-}" ]]; then
  PASSWORD="$RD_SECUREOPTION_PASSWORD"
elif [[ -n "${RD_OPTION_PASSWORD:-}" ]]; then
  PASSWORD="$RD_OPTION_PASSWORD"
elif [[ -n "${RD_CONFIG_PASSWORD_STORAGE_PATH:-}" ]]; then
  PASSWORD="$RD_CONFIG_PASSWORD_STORAGE_PATH"
elif [[ -n "${RD_CONFIG_SSH_KEY_STORAGE_PATH:-}" ]]; then
  SSHKEY=$(mktemp)
  echo "$RD_CONFIG_SSH_KEY_STORAGE_PATH" > $SSHKEY
  trap 'rm "$SSHKEY"' EXIT
else
  echo "No password or key provided"
  exit 1
fi

echo "Copying from $HOST:$SOURCE to $DESTINATION"

OPTIONS="-r -o StrictHostKeyChecking=No"
[[ "${RD_JOB_LOGLEVEL:-}" == "DEBUG" ]] && OPTIONS="$OPTIONS -v"

if [[ -n "${PASSWORD:-}" ]]; then
  # password auth
  /usr/bin/sshpass -p $PASSWORD /usr/bin/$PROTOCOL $OPTIONS $USERNAME@$HOST:"$SOURCE" $DESTINATION
else
  # key auth
  /usr/bin/$PROTOCOL -i $SSHKEY $OPTIONS $USERNAME@$HOST:"$SOURCE" $DESTINATION
fi
