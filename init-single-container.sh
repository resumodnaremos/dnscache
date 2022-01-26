#!/bin/bash
sed 's/cache.nginx-cache-proxy.lan/127.0.0.1/g;s/cache.nginx-cache-proxy.lan/127.0.0.1/g' $(find -type f /etc/nginx) -i 
bash /init-nuster.sh &
bash /init.sh
