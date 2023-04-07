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

source="$RD_CONFIG_SOURCE"
destination="$RD_CONFIG_DESTINATION"
protocol=$RD_CONFIG_PROTOCOL
host=$RD_NODE_HOSTNAME

cleanup() {
  rm -rf "$temp_dir"
}

if [[ -n "${RD_NODE_USERNAME:-}" ]]; then
  # Replace ${job.username} variable if supplied.
  username=${RD_NODE_USERNAME//\$\{job.username\}/"$RD_JOB_USERNAME"}
else
  # If no node username defined use job user.
  username="$RD_JOB_USERNAME"
fi

# Do some basic checks that the destination isn't anywhere stupid.
real_destination=$(realpath "$destination")
if [[ "$real_destination" =~ ^/etc/rundeck/ ]]; then
  echo "Invalid destination: $destination"
  exit 1
fi

# If the destination is a directory and doesn't exist, create it.
if [[ "${destination:(-1)}" == "/" && ! -d "$destination" ]]; then
  mkdir -p "$destination"
fi

temp_dir=$(mktemp -d)
trap cleanup EXIT

# Password may come from storage or an option called 'password'.
# Key may come from storage.
if [[ -n "${RD_SECUREOPTION_PASSWORD:-}" ]]; then
  echo "$RD_SECUREOPTION_PASSWORD" > "$temp_dir/password"
elif [[ -n "${RD_OPTION_PASSWORD:-}" ]]; then
  echo "$RD_OPTION_PASSWORD" > "$temp_dir/password"
elif [[ -n "${RD_CONFIG_PASSWORD_STORAGE_PATH:-}" ]]; then
  echo "$RD_CONFIG_PASSWORD_STORAGE_PATH" > "$temp_dir/password"
elif [[ -n "${RD_CONFIG_SSH_KEY_STORAGE_PATH:-}" ]]; then
  echo "$RD_CONFIG_SSH_KEY_STORAGE_PATH"  > "$temp_dir/key"
  chmod 600 "$temp_dir/key"
  if [[ -n "${RD_CONFIG_SSH_KEY_PASSPHRASE_STORAGE_PATH:-}" ]]; then
    echo "$RD_CONFIG_SSH_KEY_PASSPHRASE_STORAGE_PATH"  > "$temp_dir/passphrase"
  fi
else
  echo "No password or key provided"
  exit 1
fi

echo "Copying from $host:$source to $destination"

options="-r -o StrictHostKeyChecking=No"
[[ "${RD_JOB_LOGLEVEL:-}" == "DEBUG" ]] && options="$options -v"

if [[ -e "$temp_dir/password" ]]; then
  # Password auth.
  /usr/bin/sshpass -f "$temp_dir/password" /usr/bin/$protocol $options $username@$host:"$source" "$destination"
else
  # Key auth.
  if [[ -n "${RD_CONFIG_SSH_KEY_PASSPHRASE_STORAGE_PATH:-}" ]]; then
    /usr/bin/sshpass -P "Enter passphrase" -f "$temp_dir/passphrase" /usr/bin/$protocol -i "$temp_dir/key" $options $username@$host:"$source" "$destination"
  else
    /usr/bin/$protocol -i "$temp_dir/key" $options $username@$host:"$source" "$destination"
  fi
fi
