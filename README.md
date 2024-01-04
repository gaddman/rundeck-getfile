Rundeck plugin to retrieve a file from a remote node.

## Description
Connects to a remote node and retrieves a file, storing it on the Rundeck server. Supports SCP or SFTP.

Tested in RHEL8 and Ubuntu 22.04.

## Requirements
- `sshpass`

## Installation
Copy `rundeck-getfile.zip` to /var/lib/rundeck/libext, or install via the Rundeck web interface.

## Usage notes
- May be used with a password or SSH key. If both are provided then the password will be used.
- If you get SSH host key errors you may want to disable checking. This can be set at the Rundeck level by adding the following line to the `framework.properties` file:

  ```framework.plugin.WorkflowNodeStep.remote-file-get.options=-o StrictHostKeyChecking=No```