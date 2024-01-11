#!/bin/bash
#/var/www/cgi-bin
#http://192.168.226.30/cgi-bin/showCGIenv.cgi

echo "Content-type: text/html"
echo ""

echo "<html><body bgcolor=\"white\"><h2>CGI Runtime Environment</h2>"
echo "<pre>"
env || printenv
echo "</pre>"
echo "<h3>Input Stream is:</h3>"
echo "<pre>"
cat -
echo "(end of input stream)</pre></body></html>"
exit 0
