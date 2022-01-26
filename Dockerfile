FROM nginx:alpine
RUN apk add curl libc-dev bash grep jq
RUN wget -O- $(curl https://raw.githubusercontent.com/jiangwenyuan/nuster/master/Download.md|grep http|grep /nuster/releases/download/|grep gz |head -n1)|tar xvz
RUN cd $(ls -1nuster*|tail -n1) && make -j 3 TARGET=linux-glibc USE_LUA=1 LUA_INC=/usr/include/lua5.3 USE_OPENSSL=1 USE_PCRE=1 USE_ZLIB=1 && make install PREFIX=/usr/local/nuster
