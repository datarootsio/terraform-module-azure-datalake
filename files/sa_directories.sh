#!/bin/bash

# Start of generated script
%{ for fs in filesystems ~}
# Start of creating directories and ACLs for filesystem ${fs}
%{ for dir, acl in fs_dirs_acls[fs] ~}
# Start of commands for directory ${dir} in filesystem ${fs}
az storage fs directory create -f "${fs}" -n "${dir}"
az storage fs access set -p "${dir}" -f "${fs}" --acl "${acl}"
# End of commands for directory ${dir} in filesystem ${fs}
%{ endfor ~}
# End creating directories and ACLs for filesystem ${fs}
%{ endfor ~}
# End of generated script