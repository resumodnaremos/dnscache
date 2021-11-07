



[[ -z ${CACHEMB}   ]] && CACHEMB=512
[[ -z ${CACHETIME} ]] && CACHETIME=15m
[[ -z ${TIMEOUT}   ]] && TIMEOUT=5s
[[ -z ${CACHED_HOST}    ]] && CACHED_HOST=dnnd.de;
[[ -z ${CACHED_HOST_HEADER}    ]] && CACHED_HOST_HEADER=${CACHED_HOST};

[[ -z ${CACHED_PROTO}   ]] && CACHED_PROTO=https;

test -e /nuster.template && ( cat /nuster.template | sed 's/TIMEOUT/'${TIMEOUT}'/g;s/CACHEMB/'${CACHEMB}'/g;s/CACHETIME/'${CACHETIME}'/g;s/UPSTREAM/'${CACHED_HOST}'/g'  >  /etc/nuster/nuster.cfg  )

[[ "$CACHED_PROTO" = "http" ]] && echo { "HTTP (NO SSL ) UPSTREAM DETECTED" ; sed 's/:443 ssl verify none//g'  /etc/nuster/nuster.cfg -i ; }
test -e /etc/nuster/nuster.cfg || echo "NO CONFIG"
cat  /etc/nuster/nuster.cfg |wc -l |grep ^0$ -q && echo "EMPTY CONFIG"
cat  /etc/nuster/nuster.cfg |wc -l |grep ^0$ -q || nl /etc/nuster/nuster.cfg
while (true);do
  nuster -W -db -f /etc/nuster/nuster.cfg  ;

sleep 2;done
