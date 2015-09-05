#!/bin/bash

# silly HTTP/GET file server powered by netcat
# Date 2015年 09月 05日 星期六 18:54:23 CST
# Author 晁永生

#Usage
# $ mkfifo /tmp/f
# $ cat /tmp/f | hfs.sh <path to html root> | netcat -l 8080 >/tmp/f

code=200

response()
{
	case $code in
	200)
	printf "HTTP/1.1 200 OK\r\n"
	;;
	400)
	printf "HTTP/1.1 400 Bad Request\r\n"
	msg="<html><body><p>400</p></body></html>"
	printf "Content-Type: text/html\r\n"
	printf "Content-Length: %d\r\n" ${#msg}
	printf "\r\n%s" "$msg"
	;;
	403)
	printf "HTTP/1.1 403 Forbidden\r\n"
	msg="<html><body><p>403</p></body></html>"
	printf "Content-Type: text/html\r\n"
	printf "Content-Length: %d\r\n" ${#msg}
	printf "\r\n%s" "$msg"
	;;
	404)
	printf "HTTP/1.1 404 Not Found\r\n"
	msg="<html><body><p>404</p></body></html>"
	printf "Content-Type: text/html\r\n"
	printf "Content-Length: %d\r\n" ${#msg}
	printf "\r\n%s" "$msg"
	;;
	405)
	printf "HTTP/1.1 405 Method Not Allowed\r\n"
	msg="<html><body><p>405</p></body></html>"
	printf "Content-Type: text/html\r\n"
	printf "Content-Length: %d\r\n" ${#msg}
	printf "\r\n%s" "$msg"
	;;
	505)
	printf "HTTP/1.1 505 HTTP Version Not Supported\r\n"
	msg="<html><body><p>505</p></body></html>"
	printf "Content-Type: text/html\r\n"
	printf "Content-Length: %d\r\n" ${#msg}
	printf "\r\n%s" "$msg"
	;;
	*)
	;;
	esac
}

list()
{
	response
	msg="<html><body><ul>"
	for f in *; do
		msg=${msg}"<li><a href=\"$f\">$f</a></li>"
	done
	msg=${msg}"</body></html>"

	printf "Content-Type: text/html; charset=utf-8\r\n"
	printf "Content-Length: %d\r\n" $((${#msg}))
	printf "\r\n"
	printf "%s" "${msg}"
}

sendfile()
{
	f=$1
	totlen=`ls -l $f | awk '{print $5}'`

	response
	printf "Content-Type: application/octet-stream\r\n"
	printf "Content-Length: %d\r\n" ${totlen}
	printf "\r\n"
	dd if=$f bs=4096 count=$((totlen/4096)) 2>/dev/null
	dd if=$f skip=$((totlen/4096)) bs=4096 count=1 2>/dev/null
}

parse_http()
{
#filter request field
	idx=`expr index $1 ":"`
	[ $idx -eq 0 ] || return
	
#blank line, '\r'
	[ ${#1} -eq 1 ] && return

	[ $# -eq 3 ] || { code=400; response; return; }
	[ "$1" == "GET" ] || { code=405; response; return; }
	v=${3:0:8}
	[ "$v" == "HTTP/1.0" ] || [ "$v" == "HTTP/1.1" ] || [ "$v" == "HTTP/2.0" ] || { code=505; response; return; }

	uri=$2
	code=200
	uri=${uri#'/'}
	if [ "$uri" == "" ]; then
		list
		return
	fi
	idx=`expr index $uri "/"`
	[ $idx -eq 0 ] || { code=403; response; return; }
	[ -e $uri ] || { code=404; response; return; }

	sendfile $uri
}

# entry

[ $# -eq 1 ] || return
html_root=$1
[ -e ${html_root} ] || return
cd ${html_root}

while read line; do
	parse_http $line
done

