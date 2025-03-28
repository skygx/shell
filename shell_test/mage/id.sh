#!/bin/bash

id wang &> /dev/null ||   useradd wang

getent passwd linux

[ -f "$FILE" ] && [[ "$FILE"=~ .*\.sh$ ]] && chmod +x $FILE

grep -q no_such_user /etc/passwd || echo 'No such user'
