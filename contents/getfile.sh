#!/usr/bin/env bash

#####
# getfile.sh
# This script retrieves a file from a remote node.
# usage: getfile.sh
#
# Chris Gadd
# 2021-02-25
#####

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

# password may come from storage or an option called 'password'
if [[ -n "${RD_SECUREOPTION_PASSWORD:-}" ]]; then
  PASSWORD="$RD_SECUREOPTION_PASSWORD"
elif [[ -n "${RD_OPTION_PASSWORD:-}" ]]; then
  PASSWORD="$RD_OPTION_PASSWORD"
elif [[ -n "${RD_CONFIG_PASSWORD_STORAGE_PATH:-}" ]]; then
  PASSWORD="$RD_CONFIG_PASSWORD_STORAGE_PATH"
else
  echo "No password provided"
  exit 1
fi

echo "Copying from $HOST: $SOURCE to $DESTINATION"

OPTIONS="-r -o StrictHostKeyChecking=No"
[[ "${RD_JOB_LOGLEVEL:-}" == "DEBUG" ]] && OPTIONS="$OPTIONS -v"

/usr/bin/sshpass -p $PASSWORD /usr/bin/$PROTOCOL $OPTIONS $USERNAME@$HOST:"$SOURCE" $DESTINATION
