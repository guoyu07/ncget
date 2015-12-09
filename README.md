# ncget
silly HTTP/GET file server powered by socat

##Usage
```
$ socat tcp-listen:8080,reuseaddr exec:"./ncget.sh <html root>"
```
