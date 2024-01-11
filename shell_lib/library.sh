#!/usr/bin/env bash

initializeANSI()
{
	#esc="\033"
	esc=""
	blackf="${esc}[30m";	redf="${esc}[31m";	greenf="${esc}[32m"
	yellowf="${esc}[33m";	bluef="${esc}[34m";	purplef="${esc}[35m"
	cyanf="${esc}[36m";		whitef="${esc}[37m"

	blackb="${esc}[40m";	redb="${esc}[41m";	greenb="${esc}[42m"
	yellowb="${esc}[43m";	blueb="${esc}[44m";	purpleb="${esc}[45m"
	cyanb="${esc}[46m";		whiteb="${esc}[47m"

	boldon="${esc}[1m";		boldoff="${esc}[22m"
	italicson="${esc}[3m";	italicsoff="${esc}[23m"
	ulon="${esc}[4m";		uloff="${esc}[24m"
	invon="${esc}[7m";		invoff="${esc}[27m"

	reset="${esc}[0m"
}

in_path()
{
	cmd=$1	ourpath=$2	result=1
	oldIFS=$IFS	IFS=":"
	for directory in $ourpath
	do
		if [ -x $directory/$cmd ]; then
		result=0
		fi
	done
	IFS=$oldIFS
	return $result
}

checkForCmdInPath()
{
	var=$1
	if [ "$var" != "" ];then
	  if [ "${var:0:1}" = "/" ];then
	    if [ ! -x $var ]; then
		return 1
	    fi
	  elif ! in_path $var "$PATH" ; then
	    return 2
	  fi
	fi
}

validAlphaNum()
{
    validchars="$(echo $1 | sed -e 's/[^[:alnum:]]//g')"

    if [ "$validchars" = "$1" ] ; then
    return 0
    else
    return 1
    fi

}

nicenumber()
{
interger=$(echo $1 | cut -d. -f1)
decimal=$(echo $1 | cut -d. -f2)
if [ "$decimal" != "$1" ] ; then
    result=${DD:= '.'}$decimal
fi
thousands=$interger

while [ $thousands -gt 999 ]; do
    remainder=$(($thousands % 1000))
    while [ ${#remainder} -lt 3 ]; do
     remainder="0$remainder"
    done
    result="${TD:=","}${remainder}${result}"
    thousands=$(($thousands / 1000))
done

nicenum="${thousands}${result}"
if [ ! -z $2 ]; then
    echo $nicenum
 fi
}

exceedsDaysInMonth()
{
echo "$1  $2"
case $(echo $1|tr '[:upper:]' '[:lower:]') in
jan*) days=31   ;;  feb*) days=28   ;;
mar*) days=31   ;;  apr*) days=30   ;;
may*) days=31   ;;  jun*) days=30   ;;
jul*) days=31   ;;  aug*) days=31   ;;
sep*) days=30   ;;  oct*) days=31   ;;
nov*) days=31   ;;  dec*) days=31   ;;
*) echo "$0: Unknown month name $1" >&2
    exit 1
esac

if [ $2 -lt 1 -o $2 -gt $days ]; then
return 1
else
return 0
fi
}

isLeapYear()
{
year=$1
if [ "$((year % 4 ))" -ne 0 ]; then
    return 1
elif [ "$((year % 400 ))" -eq 0 ]; then
    return 0
elif [ "$((year % 100 ))" -eq 0 ]; then
    return 1
else
    return 0
fi
}

echon()
{
    echo "$*" | awk '{printf "%s", $0 }'
}

scriptbc()
{
if [ "$1" = "-p" ]; then
    precision=$2
    shift 2
else
    precision=2
fi
bc -q <<EOF
    scale=$precision
    $*
    quit
EOF
}

initializeANSI
