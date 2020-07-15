#!/bin/bash

# Start of generated script
%{ for fs in filesystems ~}
# Setting ACL for filesystem ${fs}
az storage fs access set -p "/" -f "${fs}" --acl "${fs_acls[fs]}"
%{ endfor ~}
#End of generated script