# Docker Cache Nuster

flexible and extreme fast https  cache using nuster and nginx


hook it intoo you webserver network ,
* it will cache only CACHED_PATH (comma separated list) to CACHED_HOST
* optionally set the `Host:` Header to CACHED_HOST_HEADER
* unless you specify STATIC_PATH (comma separated list) all non-cached requests will be sent to upstream
* if STATIC_PATH is set , then nginx will serve the static files from WEBROOT (or whatever is in the container under /var/www/html/)
* ( remember to chmod a+r for those assets under /var/www/html or allow UID/GID 101)

## OPTION A - having a spare domain/bypassing ingress proxy
* when the cache container "sees" a webserver that's not redirecting , you go straight trough nginx->nuster->upstream for the Cached_paths

## OPTION B - LOOP-BREAKING
* since the proxy has to get the real files and "the others" not , you might use the following .htaccess snippet



```
RewriteEngine On
###only rewrite if there is no cf-connecting-ip
#RewriteCond %{HTTP:CF-Connecting-IP} ^$
#RewriteRule ^(.*)\.txt$ https://yourrealdomain.lan/$1.txt [L,R=301]

###only rewrite if there is no XCacheGetRequest Header
RewriteCond %{HTTP:Xcachegetrequest} ^$
RewriteCond "%{HTTP_USER_AGENT}"   "^NameOfBadRobot"
RewriteRule ^(/combine/.*)\.mp4$ https://yourrealdomain.lan/$1.mp4 [L,R=301]
```
( the proxy will send the Xcachegetrequest)
## Notes

* REJECT_UNAUTH will throw 403 on everything except favicon.ico and CACHED_PATH
* CACHED_HOST is the real (upstream ) domain to cache


## Usage

* ( check that there is the proper docker network `nginx-proxy` or use NGINX_NETWORK in `.env`)
* see the `_dotENV.example` file and create a matching `.env`
* verify with `docker-compose config`
* start with `docker-compose up`
---


<h3>A project of the foundation</h3>
<a href="https://the-foundation.gitlab.io/"><div><img src="https://hcxi2.2ix.ch/gitlab/the-foundation/docker-cache-nuster/README.md/logo.jpg" width="480" height="270"/></div></a>
