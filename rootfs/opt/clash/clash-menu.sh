#!/bin/sh

export LANG=en_US.UTF-8

CONFIG_FILE="/opt/clash/config.yaml"
TEMPLATE_FILE="/opt/clash/config_fake-ip.yaml"

RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
PLAIN="\033[0m"

red(){
    echo -e "\033[31m\033[01m$1\033[0m"
}

green(){
    echo -e "\033[32m\033[01m$1\033[0m"
}

yellow(){
    echo -e "\033[33m\033[01m$1\033[0m"
}

reload_clash(){
    /etc/init.d/clash enable
    /etc/init.d/clash stop
    /etc/init.d/clash start
}

updateSubscribe() {
    echo ""
    read -rp "请输入订阅地址: " urlInput
    url=$urlInput
    
    if [ "$url" != "" ]; then
        echo $url >.suburl
    elif [ -e .suburl ]; then
        url=$(cat .suburl)
    else
        exit 1
    fi

    [ -d /tmp/clash/profile ] || mkdir -p /tmp/clash/profile
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
    if [ -e $TEMPLATE_FILE ]; then
        cat $TEMPLATE_FILE >$CONFIG_FILE
        sed -n '/^proxies:/,$p' $tmpName >>$CONFIG_FILE
    else
        cp $tmpName $CONFIG_FILE
        sed -ri "s@^external-controller.*@external-controller: '0.0.0.0:9090'@g" $CONFIG_FILE
        sed -i "1i tproxy-port: 7894" $CONFIG_FILE
        sed -i "1i routing-mark: 2 # Prevent cyclic redirection" $CONFIG_FILE
        sed -i '/dns:/a \    listen: 0.0.0.0:7874' $CONFIG_FILE
    fi
    # curl -X PUT -s http://127.0.0.1:9090/configs -H "Content-Type: application/json" -d '{"path":"$CONFIG_FILE"}'

    # if [ $? -ne 0 ]; then
    #     reload_clash
    # fi
    
    # netstat -na | grep 7890 >/dev/null
    # if [ $? -ne 0 ]; then
    #     reload_clash
    # fi
}

showStatus(){    
    netstat -na | grep 7890 > /dev/null
    myip=$(ip -o route get to 223.5.5.5 | awk '{print $7}')
    webUI="http://$myip:9090/ui/?hostname=$myip&port=9090"
    serviceStatus=$(/etc/init.d/clash status)
    clashCommand=$(ps | grep clash | grep "/" | awk '{print $5,$6,$7}')        
    echo "#############################################################"
    echo -e "${GREEN}serviceStatus: ${RED}${serviceStatus}${PLAIN}"
    if [ "$clashCommand" != "" ]; then
    echo -e "${GREEN}command:       ${RED}${clashCommand}"
    echo -e "${GREEN}web-ui"
    echo -e "${YELLOW}${webUI}${PLAIN}"
    fi
    echo "#############################################################"
}

menu() {
    clear
    showStatus
    echo ""
    echo -e " ${GREEN}1.${PLAIN} 开启"
    echo -e " ${GREEN}2.${PLAIN} ${RED}关闭${PLAIN}"
    echo " -------------"
    echo -e " ${GREEN}3.${PLAIN} 更新订阅"
    echo " -------------"
    echo -e " ${GREEN}0.${PLAIN} 退出"
    echo ""
    read -rp "请输入选项 [0-5]: " menuInput
    case $menuInput in
        1 ) /etc/init.d/clash stop
            /etc/init.d/clash start
            /etc/init.d/clash enable
            menu
            ;;
        2 ) /etc/init.d/clash stop
            /etc/init.d/clash disable
            menu
            ;;
        3 ) updateSubscribe 
            read -p "Press enter to continue"
            menu
            ;;
        4 ) exit 1 ;;
        5 ) exit 1 ;;
        6 ) exit 1 ;;
        * ) exit 1 ;;
    esac
}

menu
