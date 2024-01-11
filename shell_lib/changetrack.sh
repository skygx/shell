#!/bin/bash
# vim:sw=4:ts=4:et
<<INFO
    @Project :   shell
    @File    :   changetrack.sh
    @Contact :   guoxin_well@126.com
    @License :   (C)Copyright 2022-2023, xguo
	@Example ：	 changetrack.sh http://www.sina.com.cn sweet_love2000@126.com

@Modify Time            @Author    @Version    @Desciption
------------------      -------    --------    -----------
2022/11/25 下午 2:57         hello      1.0         None
INFO

sendmail=$(which sendmail)
sitearchive="/tmp/changetrack"
tmpchanges="$sitearchive/changes.$$"
fromaddr="webscraper@intuitive.com"
dirperm=755
fileperm=644

trap "$(which rm) -f $tmpchanges" 0 1 15

if [ $# -ne 2 ]; then
    echo "Usage: $(basename $0) url email" >&2
    echo "  tip: to have changes displayed on screen, use email addr '-'" >&2
    exit 1
fi

if [ ! -d $sitearchive ]; then
    if  ! mkdir $sitearchive ; then
       echo "$(basename $0) failed: couldn't create $sitearchive." >&2
       exit 1
    fi
    chmod $dirperm $sitearchive
fi

if [ "$(echo $1 | cut -c1-5)" != "http:" ]; then
    echo "Please use fully qualified URLs (e.g. start with 'http://'" >&2
    exit 1
fi

fname="$(echo $1 | sed 's/http:\/\///g' | tr '/?&' '...')"
baseurl="$(echo $1 | cut -d/ -f1-3)/"

lynx -dump "$1" | uniq > $sitearchive/${fname}.new

if [ -f "$sitearchive/$fname" ]; then
    diff $sitearchive/$fname $sitearchive/${fname}.new > $tmpchanges
    if [ -s $tmpchanges ]; then
        echo "Status: Site $1 has changed since our last check."
    else
        echo "Status: No changes for site $1 since last check."
        rm -f $sitearchive/${fname}.new
        exit 0
    fi
else
    echo "Status: first visit to $1. Copy archived for future analysis."
    mv $sitearchive/${fname}.new $sitearchive/$fname
    chmod $fileperm $sitearchive/$fname
    exit 0
fi

if [ "$2" != "-" ]; then
    (echo "Content-type: text/html"
     echo "From: $fromaddr (Web Site Change Tracker)"
     echo "Subject: Web Site $1 Has Changed"
     echo "To: $2"
     echo ""
     lynx -s -dump $1 | \
     sed -e "s|src=\"SRC=\"$baseurl|gi" \
         -e "s|href=\"HREF=\"$baseurl|gi" \
         -e "s|$baseurl\/http:|http:|g" \
    ) | $sendmail -t
else
    diff $sitearchive/$fname $sitearchive/${fname}.new
fi

mv $sitearchive/${fname}.new $sitearchive/$fname
chmod 755 $sitearchive/$fname
exit 0
