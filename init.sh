apk add --no-cache  nginx-mod-http-echo bash iproute2       #varnish ; 

##apk add --no-cache  git ;go get github.com/vektra/templar/cmd/templar 

[[ -z ${CACHED_PATH} ]] && CACHED_PATH=/;
[[ -z ${CACHED_HOST} ]] && CACHED_HOST=dnnd.de;
[[ -z ${CACHED_PROTO} ]] && CACHED_PROTO=https;
[[ -z ${VIRTUAL_HOST} ]] && VIRTUAL_HOST=nginx-cache-proxy.lan;
mkdir -p /dev/shm/nginx-{static,backup}-cache /run/nginx/
echo "#############+++init nginx cache+++#########"
( echo '
events {
    worker_connections        1024;
}
http {
    include /etc/nginx/mime.types; # This includes the built in mime types
    include /logformats.conf;
    proxy_cache_path  /dev/shm/nginx-static-cache  levels=1:2    keys_zone=STATIC:15m  inactive=15m  max_size=256m;
#    proxy_cache_path  /dev/shm/nginx-backup-cache  levels=1:2    keys_zone=BACKUP:15m  inactive=24h  max_size=256m;

    server {
      listen 80 ; 
      server_name _ ;
      location /nginx_status {        stub_status;        access_log off;        allow 127.0.0.1;        deny all;      }
      location /favicon.ico  {        return 301 '${CACHED_PROTO}'://'${CACHED_HOST}'/favicon.ico ; error_log /dev/stderr ;access_log off; }'
       echo
      for CURRENT_PATH in $(echo $CACHED_PATH|sed 's/,/\n/g;s/^ //g;s/ $//g');do

[[ "${SERVE_STATIC}" = "true"  ]]  || {      echo 'location '${CURRENT_PATH}' {
            set_real_ip_from  10.0.0.0/8     ;
            set_real_ip_from  192.168.0.0/16 ;
            set_real_ip_from  172.16.0.0/12  ;  
            set_real_ip_from  fe80::/64      ;
            set_real_ip_from  fc00::/7       ; # RFC 4193 Unique Local Addresses (ULA) 
            real_ip_header    X-Forwarded-For;
            real_ip_recursive on;
            keepalive_timeout 10m;
            proxy_connect_timeout  5s;
            proxy_send_timeout  8s;
            proxy_read_timeout  10s;
            proxy_set_header       Host '${CACHED_HOST}' ;
            proxy_pass             http://cache.'${VIRTUAL_HOST}':8000 ;
            proxy_hide_header       Cookie;
#            proxy_ignore_headers    Cookie;

#            proxy_hide_header       Set-Cookie;
#            proxy_ignore_headers    Set-Cookie;

#            proxy_pass             http://127.0.0.1:1234 ; ## varnish
#            proxy_pass             '${CACHED_PROTO}'://'${CACHED_HOST}' ;
            proxy_cache            STATIC;
            proxy_cache_valid      200  15m;
#            proxy_cache_use_stale  error http_502 http_503 http_504 timeout ;
#            proxy_set_header       X-Templar-Cache 'fallback' ;
#            proxy_set_header       X-Templar-CacheFor '15m' ;
            proxy_buffering        off;
            error_log              /dev/stderr ;'
[[ "ACCESS_LOG" = "true" ]] &&  echo ' access_log             /dev/stdout upstream;' ;
 echo  '     proxy_cache_use_stale  error timeout invalid_header updating http_500 http_502 http_503 http_504;
#            proxy_cache_valid 500 502 503 504 14m;
#            proxy_cache_valid 500 502 503 504 14m;
#            proxy_intercept_errors on;
 #           error_page 500 502 503 504 404 @fallback;

       } 
#      location @fallback {
#            access_log             /dev/stdout fallback;
#    keepalive_timeout 10m;
#    proxy_connect_timeout  2s;
#    proxy_send_timeout  5s;
#    proxy_read_timeout  6s;
#            proxy_hide_header Cookie;
##            stub_status;
#            access_log off;
##            proxy_pass             '${CACHED_PROTO}'://'${CACHED_HOST}' ;
#            proxy_pass            http://'${CACHED_HOST}' ;
#            error_log              /dev/stderr ;
#            proxy_set_header       Host '${CACHED_HOST}' ;
#            proxy_buffering        on;
#            error_log              /dev/stderr ;
#            access_log             /dev/stdout fallback;
#            proxy_cache            STATIC;
#            proxy_cache_valid 200 302 15m;
##            proxy_cache_valid 500 502 503 504 14m;
#            proxy_cache_valid 301      1h;
#            proxy_cache_valid any      14m;
#            proxy_cache_use_stale  error timeout invalid_header updating  http_500 http_502 http_503 http_504;
##            proxy_cache_valid 500 502 503 504 14m;
##            proxy_intercept_errors on;
#      } 
        ' ; } ;
[[ "${SERVE_STATIC}" = "true"  ]]  && echo 'location '${CURRENT_PATH}' {
            set_real_ip_from  10.0.0.0/8     ;
            set_real_ip_from  192.168.0.0/16 ;
            set_real_ip_from  172.16.0.0/12  ;  
            set_real_ip_from  fe80::/64      ;
            set_real_ip_from  fc00::/7       ; # RFC 4193 Unique Local Addresses (ULA) 
            real_ip_header    X-Forwarded-For;
            real_ip_recursive on;
            keepalive_timeout 10m;
            root   /var/www/html ; } ';
        done

## if REtURN_UNAUTH is set , reject everyhting except one path and favicon
[[ "${CACHED_PATH}" = "/" ]] && [[ "${RETURN_UNAUTH}" = "true"   ]] && {
        echo ' location / { return 403 ; error_log /dev/stderr ;';
        [[ "ACCESS_LOG" = "true" ]] &&  echo -n ' access_log             /dev/stdout upstream;' ;
        [[ "ACCESS_LOG" = "true" ]] ||  echo -n ' access_log off;' ; 
        echo ' }' ; } ;

[[ "${CACHED_PATH}" = "/" ]] && [[ "${RETURN_UNAUTH}" = "true"   ]] || { 
        echo ' location / { return 301 '${CACHED_PROTO}'://'${CACHED_HOST}'$request_uri ; error_log /dev/stderr ;';
        [[ "ACCESS_LOG" = "true" ]] &&  echo -n ' access_log             /dev/stdout upstream;' ;
        [[ "ACCESS_LOG" = "true" ]] ||  echo -n ' access_log off;' ; 
        echo ' }' ; } ;


echo '    }
}
 ' ) | tee /etc/nginx/nginx.conf |nl 2>&1   |sed 's/#.\+//g;'| grep -v "^$"|grep -e ';' -e '{' -e '}'
###  ^^ show config      with lines ^


#nginx -t  && nginx -g  'daemon off;'

sleep 0.2
#while (true);do varnishd -a :80 -f /etc/varnish/default.vcl -F;sleep 0.2;done &
while (true);do nginx -t  && nginx -g  'daemon off;' ;sleep 0.4;done 
#wait
