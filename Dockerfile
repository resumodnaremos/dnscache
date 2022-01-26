FROM nginx:alpine
RUN apk add curl libc-dev bash grep jq git make lua5.3-dev gcc binutils

#RUN wget -O- $(curl https://raw.githubusercontent.com/jiangwenyuan/nuster/master/Download.md|grep http|grep /nuster/releases/download/|grep gz |head -n1)|tar xvz
RUN git clone https://github.com/jiangwenyuan/nuster.git

ARG NUSTER_VERSION=5.3.0.23
ARG NUSTER_DL_URL=https://github.com/jiangwenyuan/nuster/archive/v$NUSTER_VERSION.tar.gz
ARG NUSTER_DL_FILE=nuster.tar.gz
ARG NUSTER_SRC_DIR=/tmp/nuster

RUN set -x \
        && apk add --no-cache --virtual .build-deps \
                ca-certificates \
                gcc \
                libc-dev \
                linux-headers \
                lua5.3-dev \
                make \
                openssl \
                openssl-dev \
                pcre-dev \
                readline-dev \
                tar \
                zlib-dev \
        \
        && apk add --no-cache pcre lua5.3 \
        && mkdir -p $NUSTER_SRC_DIR \
        \
        && wget -O /tmp/$NUSTER_DL_FILE $NUSTER_DL_URL \
        && tar -xvf /tmp/$NUSTER_DL_FILE -C $NUSTER_SRC_DIR --strip-components=1 \
        \
        && makeOpts=" \
                TARGET=linux-musl \
                USE_LUA=1 \
                LUA_INC=/usr/include/lua5.3 \
                LUA_LIB=/usr/lib/lua5.3 \
                USE_OPENSSL=1 \
                USE_PCRE=1 \
                PCREDIR= \
                USE_ZLIB=1 \
        " \
        && make -C $NUSTER_SRC_DIR -j "$(getconf _NPROCESSORS_ONLN)" all $makeOpts \
        && make -C $NUSTER_SRC_DIR install-bin $makeOpts \
        \
        && mkdir -p /etc/nuster \
        && cp -R $NUSTER_SRC_DIR/examples/errorfiles /etc/nuster/errors \
        \
        && rm -rf /tmp/nuster* \
        && apk del .build-deps
RUN ln -s /usr/local/sbin/nuster /usr/bin/nuster
COPY init.sh logformats.conf /
RUN chmod +x /init.sh
ENTRYPOINT /init.sh
