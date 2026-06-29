
### [SSclash](https://github.com/zerolabnet/SSClash)
```bash
opkg list-installed | grep tproxy

opkg install kmod-nft-tproxy
# opkg install iptables-mod-tproxy # for openwrt 21

# opkg remove luci-app-ssclash
# rm -rf /opt/clash/

# cp /etc/openclash/core/clash_meta /usr/bin/mihomo
[ -d /opt/clash/bin ] || mkdir -p /opt/clash/bin
# core
wget -qO- http://192.168.1.101:80/openwrt/mihomo-linux-amd64-compatible-v1.18.10.gz | gzip -dc > /opt/clash/bin/clash
chmod +x /opt/clash/bin/clash
wget -O /opt/clash/Country.mmdb http://192.168.1.101:80/openwrt/openclash/Country.mmdb 

# curl -L https://github.com/zerolabnet/ssclash/releases/download/v1.8.1/luci-app-ssclash_1.8.1-1_all.ipk -o /tmp/luci-app-ssclash_1.8.1-1_all.ipk
cd /tmp
wget http://192.168.1.101:80/openwrt/luci-app-ssclash_1.8.2-1_all.ipk 
opkg install luci-app-ssclash_1.8.2-1_all.ipk

/etc/init.d/clash stop
/etc/init.d/clash disable

ln -s /opt/clash/clash-menu.sh ~/clash-menu.sh
cd ~

# myip=$(ip -o route get to 223.5.5.5 | awk '{print $7}')
# echo -e "web-ui\nhttp://$myip:9090/ui/?hostname=$myip&port=9090"
```