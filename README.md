# ncget
silly HTTP/GET file server powered by netcat

##Usage
$ mkfifo /tmp/f

$ cat /tmp/f | ncget.sh \<rootdir\> | netcat -k -l 8080 >/tmp/f
