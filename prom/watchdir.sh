#!/bin/bash
#filename watchdir.sh
path="$*"
/usr/bin/inotifywait -mrq --timefmt '%Y-%m-%d %H:%M:%S' --format '%T %w %f %e' -e modify,delete,create,attrib $path
