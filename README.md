# Docker Cache Nuster

flexible and extreme fast https  cache using nuster and nginx 


## Notes

* REJECT_UNAUTH will throw 403 on everything except favicon.ico and CACHED_PATH
* CACHED_HOST is the real (upstream ) domain to cache


## Usage

* ( check that there is the proper docker network `nginx-proxy` or use NGINX_NETWORK in `.env`)
* see the `_dotENV.example` file and create a matching `.env`
* verify with `docker-compose config`
* start with `docker-compose up`
