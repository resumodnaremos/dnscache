#apk add --no-cache  nginx nginx-mod-http-echo bash iproute2  openssl      #varnish ;
apk upgrade;
apk add --no-cache  bash iproute2  openssl      #varnish ;
# OH NO alpine-linux
## module "/etc/nginx/modules/ngx_http_echo_module.so" version 1020001 instead of 1021003 in /etc/nginx/modules/10_http_echo.conf:1

mkdir /dev/shm/.okresponse
echo "OK" > /dev/shm/.okresponse/this_proxy_is_online

echo "nginx mods available via config:"
ls /etc/nginx/modules/*.conf -1
#bash /_0_crt-snakeoil.sh
##apk add --no-cache  git ;go get github.com/vektra/templar/cmd/templar
echo > /etc/nginx/nginx.conf &>/dev/null &
ROOTSET="false"

[[ -z ${CACHEMB}               ]] && CACHEMB=512
[[ -z ${CACHETIME}             ]] && CACHETIME=15m
[[ -z ${TIMEOUT}               ]] && TIMEOUT=5s
[[ -z ${EXPIREHEADER}          ]] && EXPIREHEADER=12h;
[[ -z ${CACHED_PATH}           ]] && CACHED_PATH=/;
[[ -z ${CACHED_HOST}           ]] && CACHED_HOST=dnnd.de;
[[ -z ${CACHED_HOST_POST}      ]] && ${CACHED_HOST};
[[ -z ${CACHED_HOST_HEADER}    ]] && CACHED_HOST_HEADER=${CACHED_HOST};

[[ -z ${CACHED_PROTO}   ]] && CACHED_PROTO=https;
[[ -z ${VIRTUAL_HOST}   ]] && VIRTUAL_HOST=nginx-cache-proxy.lan;
[[ -z ${PROXY_ROOT}     ]] && PROXY_ROOT=false
mkdir -p /dev/shm/nginx-{static,backup}-cache /run/nginx/
echo "#############+++init nginx cache+++#########"
( echo '
pid        /var/run/nginx.pid;

# Includes files with directives to load dynamic modules.
include /etc/nginx/modules/*.conf;

worker_processes  '$(($(nproc)*2))';
events {
    worker_connections        1024;
}
http {
proxy_headers_hash_max_size 1024;
proxy_headers_hash_bucket_size 512;
map $http_xcachegetrequest $xcache {
    default   $http_xcachegetrequest;
    ""        "UNCACHED";
}
## a mapping for the user ip
map $http_cf_connecting_ip $cfip {
    default   $http_cf_connecting_ip;
    ""        "127.0.0.1";
}
### 2 mappings for caching post only (ssl backend , non-ssl cache)
map $request_method $upstream_location {
  # PUT     example.com:8081;
   POST    cache.'${VIRTUAL_HOST}':8000 ;
  #PATCH   example.com:8081;
   default '${CACHED_HOST}';
}

map $request_method $upstream_proto {
    #GET     webdav_download;
    #HEAD    webdav_download;
    #PUT     webdav_upload;
    #LOCK    webdav_upload;
    POST    http;
    default https;
}
map $request_method $cached_reqtype {
  POST cachedps;
   GET upstream;
}
    include /etc/nginx/mime.types; # This includes the built in mime types
    include /logformats.conf;
    proxy_cache_path  /dev/shm/nginx-static-cache  levels=1:2    keys_zone=STATIC:15m  inactive=15m  max_size=256m;
    proxy_cache_path  /dev/shm/nginx-backup-cache  levels=1:2    keys_zone=BACKUP:15m  inactive=24h  max_size=256m;
    server {
      listen 80 ;
      server_name _ ;
      location /this_proxy_is_online { default_type text/plain;   root /dev/shm/.okresponse/ ;error_log /dev/stderr ; access_log off ; }
      location /nginx_status         { stub_status; access_log off; allow 127.0.0.1; deny all ; }'

[[ "${ROBOTS_REJECT}" = "true"  ]]  && echo 'location = /robots.txt { return 200 "User-agent: *\nDisallow: /\n"; }'
[[ "${ROBOTS_ACCEPT}" = "true"  ]]  && echo 'location = /robots.txt { return 200 "User-agent: *\nDisallow: \n" ; }'


## if  REDIRECT_FAVICON is a url
echo "${REDIRECT_FAVICON}" |grep -q -e "^http://" -e "^https://"  &&   echo 'location /favicon.ico  {        return 301 '${REDIRECT_FAVICON}' ; error_log /dev/stderr ;access_log off; }'

[[ "${REDIRECT_FAVICON}" = "true"  ]]  &&   echo 'location /favicon.ico  {        return 301 '${CACHED_PROTO}'://'${CACHED_HOST}'/favicon.ico ; error_log /dev/stderr ;access_log off; }'



[[ ! -z "${REPLACESTRING}"  ]] && {
echo '
            gunzip on;
            sub_filter_once off;
            sub_filter_types text/html text/css application/javascript text/xml;'
}

echo
[[ ! -z "$STATIC_PATH" ]]  &&   for CURRENT_PATH in $(echo $STATIC_PATH|sed 's/,/\n/g;s/^ //g;s/ $//g');do
[[ "${CURRENT_PATH}" = "/" ]] && ROOTSET="true";
      echo 'location '${CURRENT_PATH}' {
            set_real_ip_from  10.0.0.0/8     ;
            set_real_ip_from  192.168.0.0/16 ;
            set_real_ip_from  172.16.0.0/12  ;
            set_real_ip_from  fe80::/64      ;
            set_real_ip_from  fc00::/7       ; # RFC 4193 Unique Local Addresses (ULA)
            real_ip_header    X-Forwarded-For;
            real_ip_recursive on;
            keepalive_timeout 10m;
            root   /var/www/html ;
            error_log /dev/stderr;
            #proxy_cache            STATIC;
            #proxy_cache_valid      200  '${CACHETIME}';
            expires '${EXPIREHEADER}';'
[[ "${ACCESS_LOG}" = "true" ]] &&  echo ' access_log             /dev/stdout static;' ;
[[ "${ACCESS_LOG}" = "true" ]] ||  echo ' access_log             off;' ;
# custom errors , if the parameter of the error pages ends in / we proxy error_page to a directory to have images etc.
[[ ! -z "${CUSTOMFOUROFOUR}" ]] && {
[[ "${CUSTOMFOUROFOUR}" =~ \.*/$ ]] && echo 'error_page 404 /err_404/;' ## trailing slash
[[ "${CUSTOMFOUROFOUR}" =~ \.*/$ ]] || echo 'error_page 404 /err_404;'
}
echo        'add_header Cache-Control "public" ; } ';
done
CURRENT_PATH=""
 [[ ! -z "$CACHED_PATH" ]]  &&   for CURRENT_PATH in $(echo $CACHED_PATH|sed 's/,/\n/g;s/^ //g;s/ $//g');do
[[ "${CURRENT_PATH}" = "/" ]] && ROOTSET="true";
 {      echo 'location '${CURRENT_PATH}' {
            set_real_ip_from  10.0.0.0/8     ;
            set_real_ip_from  192.168.0.0/16 ;
            set_real_ip_from  172.16.0.0/12  ;
            set_real_ip_from  fe80::/64      ;
            set_real_ip_from  fc00::/7       ; # RFC 4193 Unique Local Addresses (ULA)
            real_ip_header    X-Forwarded-For;
            real_ip_recursive on;
            keepalive_timeout 10m;
            proxy_connect_timeout  13s;
            proxy_send_timeout  90s;
            proxy_read_timeout  25s;
            proxy_set_header       Host '${CACHED_HOST_HEADER}' ;
            proxy_set_header       Xcachegetrequest "$xcache";
            proxy_pass             http://cache.'${VIRTUAL_HOST}':8000 ;
            proxy_hide_header       Cookie;
#            proxy_ignore_headers    Pragma Cache-Control;

#            proxy_ignore_headers    Cookie Set-Cookie;
#            proxy_hide_header       Set-Cookie;
#            proxy_pass             http://127.0.0.1:1234 ; ## varnish
#            proxy_pass             '${CACHED_PROTO}'://'${CACHED_HOST}' ;
            proxy_cache            STATIC;
            proxy_cache_valid      200  '${CACHETIME}';
            expires '${CACHETIME}';
#            proxy_cache_use_stale  error http_502 http_503 http_504 timeout ;

            proxy_buffering        off;
            error_log              /dev/stderr ;'
[[ "${ACCESS_LOG}" = "true" ]] &&  echo ' access_log             /dev/stdout cached;' ;
[[ "${ACCESS_LOG}" = "true" ]] ||  echo ' access_log             off;' ;


# custom errors , if the parameter of the error pages ends in / we proxy error_page to a directory to have images etc.
[[ ! -z "${CUSTOMFOUROFOUR}" ]] && {
[[ "${CUSTOMFOUROFOUR}" =~ \.*/$ ]] && echo 'error_page 404 /err_404/;' ## trailing slash
[[ "${CUSTOMFOUROFOUR}" =~ \.*/$ ]] || echo 'error_page 404 /err_404;'
}


[[ ! -z "${CUSTOMFIVEOTWO}"  ]] && {
[[ "${CUSTOMFIVEOTWO}" =~ \.*/$ ]] && echo 'error_page 502 /err_502/;' ## trailing slash
[[ "${CUSTOMFIVEOTWO}" =~ \.*/$ ]] || echo 'error_page 502 /err_502;'
}


[[ "${HIDECLIENT}" = "true" ]] ||  echo '
            proxy_set_header       CF-Connecting-IP "$cfip";
            proxy_set_header       X-Forwarded-For  "$cfip";' ;
[[ "${HIDECLIENT}" = "true" ]] &&  echo '
            proxy_set_header        "User-Agent" "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:92.0) Gecko/20100101 Firefox/91.0";
            proxy_set_header       CF-Connecting-IP "10.254.254.254";
            proxy_set_header       X-Forwarded-For  "10.254.254.254";
            proxy_set_header       X-Real-IP        "10.254.254.254";
            proxy_set_header       cfip             "10.254.254.254";';

[[ ! -z "${REPLACESTRING}"  ]] && {
echo '
            sub_filter_once off;
            sub_filter_types text/html text/css application/javascript text/xml;'
for CURRSTRING in $(echo $REPLACESTRING|sed 's/,/\n/g;s/^ //g;s/ $//g');do
SEARCH=${CURRSTRING/:*/}
NEWTXT=${CURRSTRING/*:/}
echo '
            proxy_set_header Accept-Encoding "";
            sub_filter "'$SEARCH'" "'$NEWTXT'";'
done
}

 echo  '     proxy_cache_use_stale  error timeout invalid_header updating http_500 http_502 http_503 http_504;
#            proxy_cache_valid 500 502 503 504 14m;
#            proxy_cache_valid 500 502 503 504 14m;
             proxy_intercept_errors on;
#            error_page 500 502 503 504 404 @fallback;

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
#            proxy_intercept_errors on;
#      }
        ' ; } ;
        done

## requests where we cache only POST mehod

[[ ! -z "$CACHED_PATH_POSTONLY" ]]  &&   for CURRENT_PATH in $(echo $CACHED_PATH_POSTONLY|sed 's/,/\n/g;s/^ //g;s/ $//g');do
[[ "${CURRENT_PATH}" = "/" ]] && ROOTSET="true";
 {      echo 'location '${CURRENT_PATH}' {
            set_real_ip_from  10.0.0.0/8     ;
            set_real_ip_from  192.168.0.0/16 ;
            set_real_ip_from  172.16.0.0/12  ;
            set_real_ip_from  fe80::/64      ;
            set_real_ip_from  fc00::/7       ; # RFC 4193 Unique Local Addresses (ULA)
            real_ip_header    X-Forwarded-For;
            real_ip_recursive on;
            keepalive_timeout 10m;
            proxy_connect_timeout  13s;
            proxy_send_timeout  90s;
            proxy_read_timeout  25s;
            proxy_set_header       Host '${CACHED_HOST_HEADER}' ;
            proxy_set_header       Xcachegetrequest "$xcache";
            proxy_pass $upstream_proto://$upstream_location;
            proxy_hide_header       Cookie;
#            proxy_ignore_headers    Pragma Cache-Control;

#            proxy_ignore_headers    Cookie Set-Cookie;
#            proxy_hide_header       Set-Cookie;
#            proxy_pass             http://127.0.0.1:1234 ; ## varnish
#            proxy_pass             '${CACHED_PROTO}'://'${CACHED_HOST}' ;
            proxy_cache            STATIC;
            proxy_cache_valid      200  '${CACHETIME}';
            expires '${CACHETIME}';
#            proxy_cache_use_stale  error http_502 http_503 http_504 timeout ;

            proxy_buffering        off;
            error_log              /dev/stderr ;'
[[ "${ACCESS_LOG}" = "true" ]] &&  echo ' access_log             /dev/stdout cachedps ;' ;
[[ "${ACCESS_LOG}" = "true" ]] ||  echo ' access_log             off;' ;


# custom errors , if the parameter of the error pages ends in / we proxy error_page to a directory to have images etc.
[[ ! -z "${CUSTOMFOUROFOUR}" ]] && {
[[ "${CUSTOMFOUROFOUR}" =~ \.*/$ ]] && echo 'error_page 404 /err_404/;' ## trailing slash
[[ "${CUSTOMFOUROFOUR}" =~ \.*/$ ]] || echo 'error_page 404 /err_404;'
}


[[ ! -z "${CUSTOMFIVEOTWO}"  ]] && {
[[ "${CUSTOMFIVEOTWO}" =~ \.*/$ ]] && echo 'error_page 502 /err_502/;' ## trailing slash
[[ "${CUSTOMFIVEOTWO}" =~ \.*/$ ]] || echo 'error_page 502 /err_502;'
}


[[ "${HIDECLIENT}" = "true" ]] ||  echo '
            proxy_set_header       CF-Connecting-IP "$cfip";
            proxy_set_header       X-Forwarded-For  "$cfip";' ;
[[ "${HIDECLIENT}" = "true" ]] &&  echo '
            proxy_set_header        "User-Agent" "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:92.0) Gecko/20100101 Firefox/91.0";
            proxy_set_header       CF-Connecting-IP "10.254.254.254";
            proxy_set_header       X-Forwarded-For  "10.254.254.254";
            proxy_set_header       X-Real-IP        "10.254.254.254";
            proxy_set_header       cfip             "10.254.254.254";';

[[ ! -z "${REPLACESTRING}"  ]] && {
echo '
            sub_filter_once off;
            sub_filter_types text/html text/css application/javascript text/xml;'
for CURRSTRING in $(echo $REPLACESTRING|sed 's/,/\n/g;s/^ //g;s/ $//g');do
SEARCH=${CURRSTRING/:*/}
NEWTXT=${CURRSTRING/*:/}
echo '
            proxy_set_header Accept-Encoding "";
            sub_filter "'$SEARCH'" "'$NEWTXT'";'
done
}

 echo  '     proxy_cache_use_stale  error timeout invalid_header updating http_500 http_502 http_503 http_504;
#            proxy_cache_valid 500 502 503 504 14m;
#            proxy_cache_valid 500 502 503 504 14m;
             proxy_intercept_errors on;
#            error_page 500 502 503 504 404 @fallback;

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
#            proxy_intercept_errors on;
#      }
        ' ; } ;
        done


        # special endpoints NOT cached  by nginx


        CURRENT_PATH=""
         [[ ! -z "$UNCACHEDENDPOINTS" ]]  &&   for CURRENT_ENDPOINT in $(echo $UNCACHEDENDPOINTS|sed 's/,/\n/g;s/^ //g;s/ $//g');do
         CURRENT_PATH=${CURRENT_ENDPOINT/:*/}
        [[ "${CURRENT_PATH}" = "/" ]] && ROOTSET="true";

         {      echo 'location '${CURRENT_PATH}' {
                    set_real_ip_from  10.0.0.0/8     ;
                    set_real_ip_from  192.168.0.0/16 ;
                    set_real_ip_from  172.16.0.0/12  ;
                    set_real_ip_from  fe80::/64      ;
                    set_real_ip_from  fc00::/7       ; # RFC 4193 Unique Local Addresses (ULA)
                    real_ip_header    X-Forwarded-For;
                    real_ip_recursive on;
                    keepalive_timeout 10m;
                    proxy_connect_timeout  13s;
                    proxy_send_timeout  90s;
                    proxy_read_timeout  25s;
                    proxy_set_header       Host '${CACHED_HOST_HEADER}' ;
                    proxy_set_header       Xcachegetrequest "$xcache";
                    proxy_pass             '${CACHED_PROTO}'://'${CACHED_HOST}' ;
                    proxy_hide_header       Cookie;
        #            proxy_ignore_headers    Cookie;

        #            proxy_hide_header       Set-Cookie;
        #            proxy_ignore_headers    Set-Cookie;
        #            proxy_pass             http://127.0.0.1:1234 ; ## varnish
        #            proxy_pass             '${CACHED_PROTO}'://'${CACHED_HOST}' ;
                    #proxy_cache            STATIC;
                    #proxy_cache_valid      200  '${CACHETIME}';
                    #expires '${EXPIREHEADER}';
        #            proxy_cache_use_stale  error http_502 http_503 http_504 timeout ;
                                    proxy_buffering        off;
                    error_log              /dev/stderr ;'
        [[ "${ACCESS_LOG}" = "true" ]] &&  echo ' access_log             /dev/stdout nocache;' ;
        [[ "${ACCESS_LOG}" = "true" ]] ||  echo ' access_log             off;' ;

        [[ "${HIDECLIENT}" = "true" ]] ||  echo '
                    proxy_set_header       CF-Connecting-IP "$cfip";
                    proxy_set_header       X-Forwarded-For  "$cfip";' ;
        [[ "${HIDECLIENT}" = "true" ]] &&  echo '
                    proxy_set_header        "User-Agent" "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:92.0) Gecko/20100101 Firefox/91.0";
                    proxy_set_header       CF-Connecting-IP "10.254.254.254";
                    proxy_set_header       X-Forwarded-For  "10.254.254.254";
                    proxy_set_header       X-Real-IP        "10.254.254.254";
                    proxy_set_header       cfip             "10.254.254.254";';

        [[ ! -z "${REPLACESTRING}"  ]] && {
        echo '
                    sub_filter_once off;
                    sub_filter_types text/html text/css application/javascript text/xml;'
        for CURRSTRING in $(echo $REPLACESTRING|sed 's/,/\n/g;s/^ //g;s/ $//g');do
        SEARCH=${CURRSTRING/:*/}
        NEWTXT=${CURRSTRING/*:/}
        echo '
                    proxy_set_header Accept-Encoding "";
                    sub_filter "'$SEARCH'" "'$NEWTXT'";'
        done
        }

        # custom errors , if the parameter of the error pages ends in / we proxy error_page to a directory to have images etc.
        [[ ! -z "${CUSTOMFOUROFOUR}" ]] && {
        [[ "${CUSTOMFOUROFOUR}" =~ \.*/$ ]] && echo 'error_page 404 /err_404;' ## trailing slash
        [[ "${CUSTOMFOUROFOUR}" =~ \.*/$ ]] || echo 'error_page 404 /err_404/;'
        }


        [[ ! -z "${CUSTOMFIVEOTWO}"  ]] && {
        [[ "${CUSTOMFIVEOTWO}" =~ \.*/$ ]] && echo 'error_page 502 /err_502;' ## trailing slash
        [[ "${CUSTOMFIVEOTWO}" =~ \.*/$ ]] || echo 'error_page 502 /err_502/;'
        }



         echo  '     proxy_cache_use_stale  error timeout invalid_header updating http_500 http_502 http_503 http_504;
        #            proxy_cache_valid 500 502 503 504 14m;
        #            proxy_cache_valid 500 502 503 504 14m;
                    proxy_intercept_errors on;
        #            error_page 500 502 503 504 404 @fallback;

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
                done

# special endpoints cached only by nginx


CURRENT_PATH=""
 [[ ! -z "$CUSTOMENDPOINTS" ]]  &&   for CURRENT_ENDPOINT in $(echo $CUSTOMENDPOINTS|sed 's/,/\n/g;s/^ //g;s/ $//g');do
 CURRENT_PATH=${CURRENT_ENDPOINT/:*/}
 CURRENT_HOST=${CURRENT_ENDPOINT/*:/}
[[ "${CURRENT_PATH}" = "/" ]] && ROOTSET="true";

 {      echo 'location '${CURRENT_PATH}' {
            set_real_ip_from  10.0.0.0/8     ;
            set_real_ip_from  192.168.0.0/16 ;
            set_real_ip_from  172.16.0.0/12  ;
            set_real_ip_from  fe80::/64      ;
            set_real_ip_from  fc00::/7       ; # RFC 4193 Unique Local Addresses (ULA)
            real_ip_header    X-Forwarded-For;
            real_ip_recursive on;
            keepalive_timeout 10m;
            proxy_connect_timeout  13s;
            proxy_send_timeout  90s;
            proxy_read_timeout  25s;
            proxy_set_header       Host '${CURRENT_HOST}' ;
            proxy_set_header       Xcachegetrequest "$xcache";
            proxy_pass             '${CACHED_PROTO}'://'${CURRENT_HOST}' ;
            proxy_hide_header       Cookie;
#            proxy_ignore_headers    Cookie;

#            proxy_hide_header       Set-Cookie;
#            proxy_ignore_headers    Set-Cookie;
#            proxy_pass             http://127.0.0.1:1234 ; ## varnish
#            proxy_pass             '${CACHED_PROTO}'://'${CACHED_HOST}' ;
            proxy_cache            STATIC;
            proxy_cache_valid      200  '${CACHETIME}';
            expires '${EXPIREHEADER}';
#            proxy_cache_use_stale  error http_502 http_503 http_504 timeout ;

            proxy_buffering        off;
            error_log              /dev/stderr ;'
[[ "${ACCESS_LOG}" = "true" ]] &&  echo ' access_log             /dev/stdout upstream;' ;
[[ "${ACCESS_LOG}" = "true" ]] ||  echo ' access_log             off;' ;

[[ "${HIDECLIENT}" = "true" ]] ||  echo '
            proxy_set_header       CF-Connecting-IP "$cfip";
            proxy_set_header       X-Forwarded-For  "$cfip";' ;
[[ "${HIDECLIENT}" = "true" ]] &&  echo '
            proxy_set_header        "User-Agent" "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:92.0) Gecko/20100101 Firefox/91.0";
            proxy_set_header       CF-Connecting-IP "10.254.254.254";
            proxy_set_header       X-Forwarded-For  "10.254.254.254";
            proxy_set_header       X-Real-IP        "10.254.254.254";
            proxy_set_header       cfip             "10.254.254.254";';

[[ ! -z "${REPLACESTRING}"  ]] && {
echo '
            sub_filter_once off;
            sub_filter_types text/html text/css application/javascript text/xml;'
for CURRSTRING in $(echo $REPLACESTRING|sed 's/,/\n/g;s/^ //g;s/ $//g');do
SEARCH=${CURRSTRING/:*/}
NEWTXT=${CURRSTRING/*:/}
echo '
            proxy_set_header Accept-Encoding "";
            sub_filter "'$SEARCH'" "'$NEWTXT'";'
done
}

# custom errors , if the parameter of the error pages ends in / we proxy error_page to a directory to have images etc.
[[ ! -z "${CUSTOMFOUROFOUR}" ]] && {
[[ "${CUSTOMFOUROFOUR}" =~ \.*/$ ]] && echo 'error_page 404 /err_404;' ## trailing slash
[[ "${CUSTOMFOUROFOUR}" =~ \.*/$ ]] || echo 'error_page 404 /err_404/;'
}


[[ ! -z "${CUSTOMFIVEOTWO}"  ]] && {
[[ "${CUSTOMFIVEOTWO}" =~ \.*/$ ]] && echo 'error_page 502 /err_502;' ## trailing slash
[[ "${CUSTOMFIVEOTWO}" =~ \.*/$ ]] || echo 'error_page 502 /err_502/;'
}



 echo  '     proxy_cache_use_stale  error timeout invalid_header updating http_500 http_502 http_503 http_504;
#            proxy_cache_valid 500 502 503 504 14m;
#            proxy_cache_valid 500 502 503 504 14m;
            proxy_intercept_errors on;
#            error_page 500 502 503 504 404 @fallback;

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
        done

## if we cache more than the root path and RETURN_UNAUTH is set , reject everyhting except one path and favicon
[[ ! "${CACHED_PATH}" = "/" ]] && [[ "${PROXY_ROOT}" = "false"   ]] && [[ "${RETURN_UNAUTH}" = "true"   ]] && {
        echo ' location / { return 403 ; error_log /dev/stderr ;';
        [[ "${ACCESS_LOG}" = "true" ]] &&  echo -n ' access_log             /dev/stdout upstream;' ;
        [[ "${ACCESS_LOG}" = "true" ]] ||  echo -n ' access_log off;' ;
        ROOTSET="true";
        echo ' }' ; } ;


## else we redirect, but not to the blank hostname , we respect CACHED_HOST_HEADER to be the real one
[[ ! "${CACHED_PATH}" = "/" ]] && [[ "${PROXY_ROOT}" = "false"   ]]  && [[ ! "${RETURN_UNAUTH}" = "true"   ]] && {
        echo ' location / { return 301 '${CACHED_PROTO}'://'${CACHED_HOST_HEADER}'$request_uri ; error_log /dev/stderr ;';
        [[ "${ACCESS_LOG}" = "true" ]] &&  echo -n ' access_log             /dev/stdout upstream;' ;
        [[ "${ACCESS_LOG}" = "true" ]] ||  echo -n ' access_log off;' ;
        ROOTSET="true";
        echo ' }' ; } ;


## now if we do not have a valid root yet, proxy all the rest (set PROXY_ROOT ... )
[[ "${ROOTSET}" = "false" ]] && { CURRENT_PATH="/";CURRENT_HOST=${CACHED_HOST};

 {      echo 'location '${CURRENT_PATH}' {
            set_real_ip_from  10.0.0.0/8     ;
            set_real_ip_from  192.168.0.0/16 ;
            set_real_ip_from  172.16.0.0/12  ;
            set_real_ip_from  fe80::/64      ;
            set_real_ip_from  fc00::/7       ; # RFC 4193 Unique Local Addresses (ULA)
            real_ip_header    X-Forwarded-For;
            real_ip_recursive on;
            keepalive_timeout 10m;
            proxy_connect_timeout  13s;
            proxy_send_timeout  90s;
            proxy_read_timeout  25s;
            proxy_set_header       Host '${CACHED_HOST_HEADER}' ;
            proxy_set_header       Xcachegetrequest "$xcache";
            proxy_pass             '${CACHED_PROTO}'://'${CURRENT_HOST}' ;
            proxy_hide_header       Cookie;
#            proxy_ignore_headers    Cookie;

#            proxy_hide_header       Set-Cookie;
#            proxy_ignore_headers    Set-Cookie;
#            proxy_pass             http://127.0.0.1:1234 ; ## varnish
#            proxy_pass             '${CACHED_PROTO}'://'${CACHED_HOST}' ;
            proxy_cache            STATIC;
            proxy_cache_valid      200  '${CACHETIME}';
            expires '${EXPIREHEADER}';
#            proxy_cache_use_stale  error http_502 http_503 http_504 timeout ;

            proxy_buffering        off;
            error_log              /dev/stderr ;'
[[ "${ACCESS_LOG}" = "true" ]] &&  echo ' access_log             /dev/stdout upstream;' ;
[[ "${ACCESS_LOG}" = "true" ]] ||  echo ' access_log             off;' ;

[[ "${HIDECLIENT}" = "true" ]] ||  echo '
            proxy_set_header       CF-Connecting-IP "$cfip";
            proxy_set_header       X-Forwarded-For  "$cfip";' ;
[[ "${HIDECLIENT}" = "true" ]] &&  echo '
            proxy_set_header        "User-Agent" "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:92.0) Gecko/20100101 Firefox/91.0";
            proxy_set_header       CF-Connecting-IP "10.254.254.254";
            proxy_set_header       X-Forwarded-For  "10.254.254.254";
            proxy_set_header       X-Real-IP        "10.254.254.254";
            proxy_set_header       cfip             "10.254.254.254";';

[[ ! -z "${REPLACESTRING}"  ]] && {
echo '
            sub_filter_once off;
            sub_filter_types text/html text/css application/javascript text/xml;'
for CURRSTRING in $(echo $REPLACESTRING|sed 's/,/\n/g;s/^ //g;s/ $//g');do
SEARCH=${CURRSTRING/:*/}
NEWTXT=${CURRSTRING/*:/}
echo '
            proxy_set_header Accept-Encoding "";
            sub_filter "'$SEARCH'" "'$NEWTXT'";'
done
}

# custom errors , if the parameter of the error pages ends in / we proxy error_page to a directory to have images etc.
[[ ! -z "${CUSTOMFOUROFOUR}" ]] && {
[[ "${CUSTOMFOUROFOUR}" =~ \.*/$ ]] && echo 'error_page 404 /err_404;' ## trailing slash
[[ "${CUSTOMFOUROFOUR}" =~ \.*/$ ]] || echo 'error_page 404 /err_404/;'
}


[[ ! -z "${CUSTOMFIVEOTWO}"  ]] && {
[[ "${CUSTOMFIVEOTWO}" =~ \.*/$ ]] && echo 'error_page 502 /err_502;' ## trailing slash
[[ "${CUSTOMFIVEOTWO}" =~ \.*/$ ]] || echo 'error_page 502 /err_502/;'
}



 echo  '     proxy_cache_use_stale  error timeout invalid_header updating http_500 http_502 http_503 http_504;
#            proxy_cache_valid 500 502 503 504 14m;
#            proxy_cache_valid 500 502 503 504 14m;
            proxy_intercept_errors on;
#            error_page 500 502 503 504 404 @fallback;

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
        ' ; }







    echo  ; };

### custom pages

[[ ! -z "${CUSTOMFIVEOTWO}"  ]] &&  { echo '
        location /err_502 {  proxy_pass '${CUSTOMFIVEOTWO}'  ;resolver 1.1.1.1 9.9.9.9 valid=90s;error_log /dev/stderr ;access_log off;'
        [[ ! -z "${REPLACESTRING}"  ]] && {
        echo '
                    sub_filter_once off;
                    sub_filter_types text/html text/css application/javascript text/xml;'
        for CURRSTRING in $(echo $REPLACESTRING|sed 's/,/\n/g;s/^ //g;s/ $//g');do
        SEARCH=${CURRSTRING/:*/}
        NEWTXT=${CURRSTRING/*:/}
        echo '
                    proxy_set_header Accept-Encoding "";
                    sub_filter "'$SEARCH'" "'$NEWTXT'";'
        done
        }
        echo 'proxy_hide_header       Cookie; } ' ; } ;
[[ ! -z "${CUSTOMFOUROFOUR}" ]] && { echo '
        location /err_404 {  proxy_pass '${CUSTOMFOUROFOUR}' ;resolver 1.1.1.1 9.9.9.9 valid=90s;error_log /dev/stderr ;access_log off;'
        [[ ! -z "${REPLACESTRING}"  ]] && {
        echo '
                    sub_filter_once off;
                    sub_filter_types text/html text/css application/javascript text/xml;'
        for CURRSTRING in $(echo $REPLACESTRING|sed 's/,/\n/g;s/^ //g;s/ $//g');do
        SEARCH=${CURRSTRING/:*/}
        NEWTXT=${CURRSTRING/*:/}
        echo '
                    proxy_set_header Accept-Encoding "";
                    sub_filter "'$SEARCH'" "'$NEWTXT'";'
        done
        }
        echo 'proxy_hide_header       Cookie; } ' ; } ;


### below we close http and server section
echo '    }

}
 ' ) | tee /etc/nginx/nginx.conf |grep -v '^#'  |nl 2>&1  |sed 's/#.\+//g;'| grep -v "^$"|grep -e ';' -e '{' -e '}'
###  ^^ show config      with lines ^
#

#nginx -t  && nginx -g  'daemon off;'
 
test -e /single_container && sed 's/cache.'${VIRTUAL_HOST}'/127.0.0.1/g' -i /etc/nginx/nginx.conf 

sleep 0.2
#while (true);do varnishd -a :80 -f /etc/varnish/default.vcl -F;sleep 0.2;done &
while (true);do curl -s 127.0.0.1/nginx_status|sed 's/$/|/g'|tr -d '\n'|sed 's/^/STATS: /g';echo;sleep 3600;done &
while (true);do nginx -t  && nginx -g  'daemon off;' ;sleep 0.4;done
#wait
