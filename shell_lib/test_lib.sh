#!/bin/bash

. library.sh

#set -- $(echo $1|sed 's/[\/\-]/ /g')

echo "$1 $2 $3"
month="$(echo $1|cut -d\  -f1)"
day="$(echo $1|cut -d\  -f2)"
year="$(echo $1|cut -d\  -f3)"

exceedsDaysInMonth "$1" "$2"

isLeapYear $3

<<COM
nicenumber $1 1

echo -n "Enter input: "
read input
if ! validAlphaNum "$input" ; then
    echo "Your input must consist of only letters and numbers." >&2
    exit 1
else
    echo "Input is valid"
fi

echo -e "${yellowf}This is a phrase in yellow${redb} and red${reset}"

cat << EOF
${yellowf}This is a phrase in yellow${redb} and red${reset}
EOF

cat << "EOF"
${yellowf}This is a phrase in yellow${redb} and red${reset}
EOF

if [ $# -ne 1 ]; then
  echo "Usage: $0 command" >&2
  exit 1
fi

checkForCmdInPath "$1"
case $? in
  0) echo "$1 found in PATH"	;;
  1) echo "$1 not found or not executable"	;;
  2) echo "$1 not found in PATH"	;;
esac

COM



exit 0
