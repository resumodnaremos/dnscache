FROM nginx:alpine
RUN apk add curl libc-dev bash grep jq
RUN wget -O - curl https://raw.githubusercontent.com/jiangwenyuan/nuster/master/Download.md|grep http|grep /nuster/releases/download/|grep gz |head -n1)|tar xvz
