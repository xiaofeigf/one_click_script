#!/bin/sh



checkArchitecture(){
	# https://stackoverflow.com/questions/48678152/how-to-detect-386-amd64-arm-or-arm64-os-architecture-via-shell-bash

    
	case $(uname -m) in
		i386)   osArchitecture="386" ;;
		i686)   osArchitecture="386" ;;
		x86_64) osArchitecture="amd64" ;;
		arm)    dpkg --print-architecture | grep -q "arm64" && osArchitecture="arm64" || osArchitecture="arm" ;;
		aarch64)    dpkg --print-architecture | grep -q "arm64" && osArchitecture="arm64" || osArchitecture="arm" ;;
		* )     osArchitecture="arm" ;;
	esac

    
}


getLinuxOSRelease(){

    checkArchitecture

    # NAME="OpenWrt"
    # VERSION="SNAPSHOT"
    # ID="openwrt"
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        osInfo=$NAME
        osID=$ID
        osReleaseVersionNo=$VERSION_ID
    fi

    echo
    echo " ================================================== "
    echo "OS: ${osInfo}, ${ID}, ${VERSION_ID}   CPU: $osArchitecture"
}


getGithubLatestReleaseVersion(){
    # https://github.com/p4gefau1t/trojan-go/issues/63
    wget --no-check-certificate -qO- https://api.github.com/repos/$1/tags | grep 'name' | cut -d\" -f4 | head -1 | cut -b 1-
}


mosdnsDownloadPath="/tmp"
mosdnsEtcPath="/etc/mosdns"

getIPDKdownloadFilename(){
    # mosdnsIPK_array=($(wget -qO- https://op.supes.top/packages/x86_64/ | grep -E "mosdns|v2ray" | awk -F'<a href=\"' '/ipk/{print $2}' | cut -d\" -f1 | sort -V))

    mosdnsIPK_array=$(wget -qO- https://op.supes.top/packages/x86_64/ | grep -E "mosdns|v2ray" | awk -F'<a href=\"' '/ipk/{print $2}' | cut -d\" -f1 | sort -V)

    for filename in ${mosdnsIPK_array}; do

        if [ "${filename#*luci-app-mosdns}" != "$filename" ]; then
            mosdnsLuciFilename1="${filename}"
            mosdnsLuciUrl2="https://op.supes.top/packages/x86_64/${mosdnsLuciFilename1}"
            echo "1 $mosdnsLuciFilename1"

        elif [ "${filename#*mosdns}" != "$filename" ]; then
            mosdnsFilename1="${filename}"
            mosdnsUrl1="https://op.supes.top/packages/x86_64/${mosdnsFilename1}"
            echo "2 $mosdnsFilename1"

        elif [ "${filename#*geosite}" != "$filename" ]; then
            v2rayGeoSiteFilename="${filename}"
            v2rayGeoSiteUrl1="https://op.supes.top/packages/x86_64/${v2rayGeoSiteFilename}"
            echo "4 $v2rayGeoSiteFilename"

        elif [ "${filename#*geoip}" != "$filename" ]; then
            v2rayGeoIpFilename="${filename}"
            v2rayGeoIpUrl1="https://op.supes.top/packages/x86_64/${v2rayGeoIpFilename}"
            echo "3 $v2rayGeoIpFilename"            
        else
            echo
        fi
    done
}

installMosdns(){
    mosdnsFilename1="mosdns_cee9e6d-55_x86_64.ipk"
    mosdnsLuciFilename1="luci-app-mosdns_git-22.142.44511-c664869_all.ipk"

    mosdnsUrl1="https://op.supes.top/packages/x86_64/mosdns_cee9e6d-55_x86_64.ipk"
    mosdnsLuciUrl2="https://op.supes.top/packages/x86_64/luci-app-mosdns_git-22.142.44511-c664869_all.ipk"

    v2rayGeoSiteFilename="v2ray-geosite_20220425025949-4_all.ipk"
    v2rayGeoIpFilename="v2ray-geoip_202204210050-4_all.ipk"

    v2rayGeoSiteUrl1="https://op.supes.top/packages/x86_64/v2ray-geosite_20220425025949-4_all.ipk"
    v2rayGeoIpUrl1="https://op.supes.top/packages/x86_64/v2ray-geoip_202204210050-4_all.ipk"

    getIPDKdownloadFilename


    geositeFilename="geosite.dat"
    geoipFilename="geoip.dat"
    cnipFilename="cn.dat"

    # versionV2rayRulesDat=$(getGithubLatestReleaseVersion "Loyalsoldier/v2ray-rules-dat")
    # geositeUrl="https://github.com/Loyalsoldier/v2ray-rules-dat/releases/download/202205162212/geosite.dat"
    # geoipeUrl="https://github.com/Loyalsoldier/v2ray-rules-dat/releases/download/202205162212/geoip.dat"
    # cnipUrl="https://github.com/Loyalsoldier/geoip/releases/download/202205120123/cn.dat"

    geositeUrl="https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geosite.dat"
    geoipeUrl="https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geoip.dat"
    cnipUrl="https://raw.githubusercontent.com/Loyalsoldier/geoip/release/cn.dat"


    echo
    echo " ================================================== "
    echo " ?????????????????????DNS?????????, ???????????????????????????"
    echo " ???????????????DNS?????????, ??????????????????DNS??????????????????????????????"
    echo " ????????????????????????????????????DNS???????????????"
    echo
    read -r -p "?????????????????????DNS?????????? ??????????????????????????????, ?????????[y/N]:" isAddNewDNSServerInput
    isAddNewDNSServerInput=${isAddNewDNSServerInput:-n}

    addNewDNSServerIPText=""
    addNewDNSServerDomainText=""
    if [[ "$isAddNewDNSServerInput" == [Nn] ]]; then
        echo 
    else
        echo
        echo " ================================================== "
        echo " ??????????????????DNS?????????IP ???????????? 1.1.1.1"
        echo " ???????????????53 ??????DNS????????????, ????????????53????????????????????????, ???????????? 1.1.1.1:8053"
        echo 
        read -r -p "???????????????DNS?????????IP??????, ?????????:" isAddNewDNSServerIPInput

        if [ -n "${isAddNewDNSServerIPInput}" ]; then
        read -r -d '' addNewDNSServerIPText << EOM
        - addr: "udp://${isAddNewDNSServerIPInput}"
          idle_timeout: 500
          trusted: true
EOM

        fi

        echo
        echo " ================================================== "
        echo " ??????????????????DNS?????????????????? ????????????DOH??????, ???????????? www.dns.com"
        echo " ????????????????????? /dns-query ??????DOH??????, ?????? https://www.dns.com/dns-query"
        echo 
        read -r -p "???????????????DOH??????????????????, ????????????https://, ?????????????????????:" isAddNewDNSServerDomainInput

        if [ -n "${isAddNewDNSServerDomainInput}" ]; then
        read -r -d '' addNewDNSServerDomainText << EOM
        - addr: "https://${isAddNewDNSServerDomainInput}/dns-query"       
          idle_timeout: 400
          trusted: true
EOM
        fi
    fi





    echo
    echo "Downloading mosdns.  ???????????? mosdns.ipk ???????????????"
    echo
    wget -O ${mosdnsDownloadPath}/${mosdnsFilename1} ${mosdnsUrl1}
    wget -O ${mosdnsDownloadPath}/${mosdnsLuciFilename1} ${mosdnsLuciUrl2}

    wget -O ${mosdnsDownloadPath}/${v2rayGeoSiteFilename} ${v2rayGeoSiteUrl1}
    wget -O ${mosdnsDownloadPath}/${v2rayGeoIpFilename} ${v2rayGeoIpUrl1}


    echo
    echo "Downloading geosite and geoip. ???????????? geosite.dat geoip.dat ???????????????"
    echo

    wget -O ${mosdnsDownloadPath}/${geositeFilename} ${geositeUrl}
    wget -O ${mosdnsDownloadPath}/${geoipFilename} ${geoipeUrl}
    wget -O ${mosdnsDownloadPath}/${cnipFilename} ${cnipUrl}

    echo
    echo "Install mosdns.ipk and luci-app-mosdns.ipk. ???????????? mosdns.ipk luci-app-mosdns.ipk"
    echo

    opkg install ${v2rayGeoSiteFilename}
    opkg install ${v2rayGeoIpFilename}

    opkg install ${mosdnsFilename1}
    opkg install ${mosdnsLuciFilename1}

    cd ${mosdnsDownloadPath}

    mkdir -p ${mosdnsEtcPath}
    cp -f ${mosdnsDownloadPath}/${geositeFilename} ${mosdnsEtcPath}
    cp -f ${mosdnsDownloadPath}/${geoipFilename} ${mosdnsEtcPath}
    cp -f ${mosdnsDownloadPath}/${cnipFilename} ${mosdnsEtcPath}

    rm -f "/tmp/mosdns.txt"
    rm -f "${mosdnsEtcPath}/cus_config.yaml"

    cat > "${mosdnsEtcPath}/cus_config.yaml" <<-EOF    

log:
  level: info
  file: "/tmp/mosdns.txt"
plugin:
  - tag: main_server
    type: server
    args:
      entry:
        - main_sequence
      server:
        - protocol: udp
          addr: "[::1]:5335"
        - protocol: tcp
          addr: "[::1]:5335"
        - protocol: udp
          addr: "127.0.0.1:5335"
        - protocol: tcp
          addr: "127.0.0.1:5335"

  - tag: main_sequence
    type: sequence
    args:
      exec:
        # ad block
        # - if:
        #     - query_is_ad_domain
        #   exec:
        #     - _block_with_nxdomain
        #     - _return

        # hosts map
        # - map_hosts

        - mem_cache

        - if:
            - query_is_gfw_domain
          exec:
            - forward_remote
            - _return

        - if:
            - query_is_local_domain
            - "!_query_is_common"
          exec:
            - forward_local
            - _return 

        - if:
            - query_is_non_local_domain
          exec:
            - _prefer_ipv4
            - forward_remote
            - _return

        - primary:
            - forward_local
            - if:
                - "!response_has_local_ip"
              exec:
                - _drop_response
          secondary:
            - _prefer_ipv4
            - forward_remote
          fast_fallback: 200
          always_standby: true


  - tag: mem_cache
    type: cache
    args:
      size: 2048
      # use redis as the backend cache
      # redis: 'redis://localhost:6379/0'
      # redis_timeout: 50
      lazy_cache_ttl: 86400
      lazy_cache_reply_ttl: 30

  # hosts map
  # - tag: map_hosts
  #   type: hosts
  #   args:
  #     hosts:
  #       - 'google.com 0.0.0.0'
  #       - 'api.miwifi.com 127.0.0.1'
  #       - 'www.baidu.com 0.0.0.0'


  - tag: forward_local
    type: fast_forward
    args:
      upstream:
        - addr: "udp://114.114.114.114"
        - addr: "udp://223.5.5.5"
        - addr: "https://dns.alidns.com/dns-query"
          idle_timeout: 20
          trusted: true
        - addr: "https://doh.pub/dns-query"
          idle_timeout: 25
          trusted: true


  - tag: forward_remote
    type: fast_forward
    args:
      upstream:
${addNewDNSServerIPText}
${addNewDNSServerDomainText}

        - addr: "udp://208.67.222.222"
          trusted: true
        - addr: "https://doh.opendns.com/dns-query"       
          idle_timeout: 400
          trusted: true

        #- addr: "udp://172.105.216.54"   
        - addr: "udp://5.2.75.231"
          idle_timeout: 400
          trusted: true

        - addr: "udp://1.0.0.1"
          trusted: true
        - addr: "tls://1dot1dot1dot1.cloudflare-dns.com"
        - addr: "https://dns.cloudflare.com/dns-query"
          idle_timeout: 400
          trusted: true

        - addr: "udp://185.121.177.177"
        - addr: "udp://169.239.202.202"
          idle_timeout: 400
          trusted: true

        - addr: "udp://94.130.180.225"
        - addr: "udp://78.47.64.161"
          trusted: true
        - addr: "tls://dns-dot.dnsforfamily.com"
        - addr: "https://dns-doh.dnsforfamily.com/dns-query"
          dial_addr: "94.130.180.225:443"
          idle_timeout: 400


        - addr: "udp://101.101.101.101"
          trusted: true
        - addr: "udp://101.102.103.104"
          trusted: true 
        - addr: "tls://101.101.101.101"
        - addr: "https://dns.twnic.tw/dns-query"
          idle_timeout: 400
          trusted: true

        - addr: "udp://172.104.237.57"

        - addr: "udp://51.38.83.141"          
        - addr: "tls://dns.oszx.co"
        - addr: "https://dns.oszx.co/dns-query"
          idle_timeout: 400 

        - addr: "udp://176.9.93.198"
        - addr: "udp://176.9.1.117"                  
        - addr: "tls://dnsforge.de"
        - addr: "https://dnsforge.de/dns-query"
          idle_timeout: 400

        - addr: "udp://88.198.92.222"                  
        - addr: "tls://dot.libredns.gr"
        - addr: "https://doh.libredns.gr/dns-query"
          idle_timeout: 400 


  - tag: query_is_local_domain
    type: query_matcher
    args:
      domain:
        - "ext:./geosite.dat:cn"

  - tag: query_is_gfw_domain
    type: query_matcher
    args:
      domain:
        - "ext:./geosite.dat:gfw"

  - tag: query_is_non_local_domain
    type: query_matcher
    args:
      domain:
        - "ext:./geosite.dat:geolocation-!cn"

  - tag: query_is_ad_domain
    type: query_matcher
    args:
      domain:
        - "ext:./geosite.dat:category-ads-all"

  - tag: response_has_local_ip
    type: response_matcher
    args:
      ip:
        # ????????????geoip.dat??????
        # - "ext:./geoip.dat:cn"
        # ???????????????cn.dat??????, ???????????????????????????
        - "ext:./cn.dat:cn"

EOF


    echo
    echo "Install mosdns success! ??????mosdns??????!"
    echo
}

main(){
    checkArchitecture
    getLinuxOSRelease

    echo
    echo " ================================================== "

    if [ "${osInfo}" = "OpenWrt" ]; then
        if [ "${osArchitecture}" = "amd64" ]; then
            echo "Prepare to install Mosdns on OpenWrt X86"
            echo "???????????? OpenWrt X86 ??? Mosdns, ?????? opkg ??????"
        else
            echo "Only support X86 on Openwrt, not support on Arm Openwrt ! "
            echo "??????????????????X86????????????, ?????????Arm ?????????, ???????????????Arm??????????????????Mosdns????????? ! "
            exit
        fi
    else
        echo "Only support OpenWrt! "
        exit
    fi


    installMosdns

}

main
