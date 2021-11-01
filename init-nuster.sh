


test -e /nuster.template && ( cat /nuster.template |sed 's/UPSTREAM/'${CACHED_HOST}'/g'  >  /etc/nuster/nuster.cfg  ) 

test -e /etc/nuster/nuster.cfg || echo "NO CONFIG"
cat  /etc/nuster/nuster.cfg |wc -l |grep ^0$ -q && echo "EMPTY CONFIG"

while (true);do
  nuster -W -db -f /etc/nuster/nuster.cfg  ;

sleep 2;done
