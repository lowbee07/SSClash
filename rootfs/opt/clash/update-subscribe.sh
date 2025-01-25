#!/bin/sh

reload_clash(){
    /etc/init.d/clash enable
    /etc/init.d/clash stop
    /etc/init.d/clash start
}

update() {
    url=$1
    [ -d /tmp/clash/profile ] || mkdir /tmp/clash/profile
    tmpName=/tmp/clash/profile/$(cat /proc/sys/kernel/random/uuid | cut -d "-" -f 1).yaml
    wget --no-check-certificate --user-agent="clash-verge/v1.6.0" -O $tmpName $url

    if [ $? -ne 0 ]; then
        echo fetch url ERROR
        exit 1
    fi
    grep MATCH $tmpName >/dev/null
    if [ $? -ne 0 ]; then
        echo config file is unknow format
        exit 1
    fi

    # grep MATCH /opt/clash/*.yaml | awk -F ':' '{print $1, $2}'
    # tmpName=
    if [ -e /opt/clash/config_fake-ip.yaml ]; then
        cat /opt/clash/config_fake-ip.yaml >/opt/clash/config.yaml
        sed -n '/^proxies:/,$p' $tmpName >>/opt/clash/config.yaml
    else
        cp $tmpName /opt/clash/config.yaml
        sed -ri "s@^external-controller.*@external-controller: '0.0.0.0:9090'@g" /opt/clash/config.yaml
        sed -i "1i tproxy-port: 7894" /opt/clash/config.yaml
        sed -i "1i routing-mark: 2 # Prevent cyclic redirection" /opt/clash/config.yaml
        sed -i '/dns:/a \    listen: 0.0.0.0:7874' /opt/clash/config.yaml
    fi
    curl -X PUT -s http://127.0.0.1:9090/configs -H "Content-Type: application/json" -d '{"path":"/opt/clash/config.yaml"}'

    if [ $? -ne 0 ]; then
        reload_clash
    fi
    
    netstat -na | grep 7890 >/dev/null
    if [ $? -ne 0 ]; then
        reload_clash
    fi
    
    myip=$(ip -o route get to 223.5.5.5 | awk '{print $7}')
    echo -e "web-ui\nhttp://$myip:9090/ui/?hostname=$myip&port=9090"
}

if [ "$1" != "" ]; then
    update $1
    echo $1 >.suburl
    exit 0
fi
if [ -e .suburl ]; then
    update $(cat .suburl)
    exit 0
fi
echo -e "usage: \n\t$0 http://xxx.xx/subUrl"
exit 1
