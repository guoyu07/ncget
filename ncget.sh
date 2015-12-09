#!/bin/bash

# silly HTTP/GET file server
# Date 2015年 09月 05日 星期六 18:54:23 CST
# Author 晁永生

#Usage
# $ socat tcp-listen:8080,reuseaddr exec:"./ncget.sh <html root>"

dbg()
{
	echo "DEBUG: $*" >/dev/stderr
}

response()
{
	code=$1

	[ $code -eq 200 ] && { printf "HTTP/1.1 200 OK\r\n"; return; }

	case $code in
	400)
	printf "HTTP/1.1 400 Bad Request\r\n"
	;;
	403)
	printf "HTTP/1.1 403 Forbidden\r\n"
	;;
	404)
	printf "HTTP/1.1 404 Not Found\r\n"
	;;
	405)
	printf "HTTP/1.1 405 Method Not Allowed\r\n"
	;;
	505)
	printf "HTTP/1.1 505 HTTP Version Not Supported\r\n"
	;;
	*)
	;;
	esac

	msg="<html><body><p>${code}</p></body></html>"
	printf "Content-Type: text/html\r\n"
	printf "Content-Length: %d\r\n" ${#msg}
	printf "\r\n%s" "$msg"
}

list()
{
	p="${1%/}"
	pushd $p >/dev/null

	msg="<html><body><ul>"
	for f in *;do
		msg=${msg}"<li><a href=\"${p}/$f\">$f</a></li>"
	done
	msg=${msg}"</ul></body></html>"

	totlen=`expr length "${msg}"`

	response 200
	printf "Content-Type: text/html; charset=utf-8\r\n"
	printf "Content-Length: %d\r\n" $totlen
	printf "\r\n"
	printf "%s" "${msg}"

	popd >/dev/null
}

sendfile()
{
	f=$1
	totlen=`ls -l "$f" | awk '{print $5}'`

	response 200
	printf "Content-Type: application/octet-stream\r\n"
	printf "Content-Length: %d\r\n" ${totlen}
	printf "\r\n"
	dd if="$f" bs=4096 count=$((totlen/4096)) 2>/dev/null
	dd if="$f" skip=$((totlen/4096)) bs=4096 count=1 2>/dev/null
}

http()
{
	#filter request field
	idx=`expr index $1 ":"`
	[ $idx -eq 0 ] || return
	
	#blank line, '\r'
	[ ${#1} -eq 1 ] && return

	[ $# -eq 3 ] || { response 400; return; }
	[ "$1" == "GET" ] || { response 405; return; }
	v=${3:0:8}
	[ "$v" == "HTTP/1.0" ] || [ "$v" == "HTTP/1.1" ] || [ "$v" == "HTTP/2.0" ] || { response 505; return; }

	uri=$2
	uri=${uri#'/'}

	uri=$(perl -e "use URI::Escape;print uri_unescape(\"$uri\")")

	[ "$uri" == "" ] && { list "./"; return; }
	[ -e "$uri" ] || { response 404; return; }
	[ -f "$uri" ] && { sendfile "$uri"; return; }
	[ -d "$uri" ] && { list "$uri"; return; }
	response 400
}

# entry

[ $# -eq 1 ] || return
rootdir=$1
[ -e ${rootdir} ] || return
cd ${rootdir}

while read line; do
	dbg $line
	http $line
done

