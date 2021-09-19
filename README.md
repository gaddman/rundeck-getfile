Rundeck plugin to retrieve a file from a remote node.

## Description
Connects to a remote node and retrieves a file, storing it on the Rundeck server. Supports SCP or SFTP.

Tested in RHEL7 and Ubuntu 20.04.

## Requirements
- `sshpass`

## Installation
Copy `rundeck-getfile.zip` to /var/lib/rundeck/libext, or install via the Rundeck web interface.

## Usage
May be used with a password or SSH key. If both are provided then the password will be used.