. $PWD/conf.rc

_CONNTRACK_BEAUTY_ESTABLISHED(){
	CMD="conntrack -L"

	$CMD 2> /dev/null | awk '/udp|icmp/{ next }{
		PROTO=$1
		STATE=$4
		IP_S=$5
		IP_D=$6
		DPORT=$8
		SPORT=$7
	}{
		gsub(/src=/, "", IP_S);
		gsub(/dst=/, "", IP_D);
		gsub(/sport=/, "", SPORT);
		gsub(/dport=/, "", DPORT);
	}{
		print "|", STATE, "\t|", IP_S":"SPORT, "\t----(", PROTO, ")---->", IP_D":"DPORT
	}' | sort |grep -i "ESTAB"
}

_NETCAT_CHECK_TEMPLATE(){
    local HOST="$1"
    local PORT="$2"
    local SRVCNAME="$3"
    nc -z -w1 "$HOST" "$PORT"  &> /dev/null && (
        echo -e "$SRVCNAME:$PORT $OK"
        exit 0
    ) || (
        echo -e "$SRVCNAME:$PORT $NOK"
        exit 2
    )
}


_PING_CHECK(){
    local HOST="$1"
    pingout=$(ping -q -W1 -c1 "$HOST") ; local ret="$?"
    [ "$ret" -eq 0 ] && {
        local rtt=$(awk -F'/' '/rtt/{print $5}' <<< "$pingout")
        local packetloss=$(awk -F',' '/loss/{print $3}' <<< "$pingout")
        echo -e "PING $OK\n${SPACE}${MARKEND}$rtt ms,$packetloss"
    } || {
        echo -e "PING $NOK"
    }
}


_HTTPD_CHECK(){
    local HOST="$1"
    local PORTHTTP="${2:-80}"
    local SRVCNAME="${3:-HTTPd}"
    curlout=$(set -o pipefail ; curl -v --connect-timeout 2 -w 'total_time:%{time_total} s' -o /dev/null -s "$HOST:$PORTHTTP" |&grep -Pe "time|< Server") ; ret="${PIPESTATUS[0]}"
    httpd_version=$(awk '/Serv/{print $3}' <<< "$curlout")
    resp_time=$(awk -F':' '/time/{print $2}' <<< "$curlout")
    [ "$ret" -eq 0 ] && {
                echo -e "$SRVCNAME:$PORTWEB $OK\n${SPACE}${MARK}${httpd_version:-no_version}\n${SPACE}${MARKEND}${curlout##*total_}"
        } || {
                echo -e "$SRVCNAME:$PORTWEB $NOK"
        }
}

_SSHD_CHECK(){
    local HOST="$1"
    local PORTSSH="${2:-22}"
    nagios_cmd="$PWD/check_ssh"
    # sshd_cmd="echo ''|netcat -zv $HOST $PORTSSH"
    [ $(which "$nagios_cmd") ] && sshd_cmd="$nagios_cmd"
    sshout=$($sshd_cmd -t1 -p "$PORTSSH" "$HOST") && {
                echo -e "SSH:$PORTSSH $OK\n${SPACE}${MARKEND}$(awk -F'[-(]' '{print $2}' <<< $sshout)"
        } || {
                echo -e "SSH:$PORTSSH $NOK"
        }
}
_TEST(){
t=':O';b='c====8';while true; do for ((i=0 ; i < $((${#b}-1)) ; i++ )); do tput cup 10 0 ; echo -n "$t${b:i:${#b}} "; sleep 0.5; done ; for ((j=$((${#b}-1)) ; j > 0 ; j-- )); do tput cup 10 0 ; echo -n "$t${b:j:${#b}} 
"; sleep 0.5; done; done
}

_DNS_CHECK(){
    local DNSSERV="$1"
    local DNS_NDD_QUERY="${2:-$(hostname).$(domainname)}"
    local DNS_RESP_EXPECTED="${3:-127.0.0.1}"
    dnsout=$($PWD/check_dns -t1 -w2 -c5 -H "$DNS_NDD_QUERY" -a "$DNS_RESP_EXPECTED" -s "$DNSSERV")
    case "$?" in
        0)
            echo -e "DNS $OK\n${SPACE}${MARKEND} $(awk -F'[ |]' '{print $3 "s - ""'"$DNS_NDD_QUERY($DNS_RESP_EXPECTED)"'", "<->", $12}' <<< $dnsout)" ;;
        1)
            echo -e "DNS $NOK\n${SPACE}${MARKEND}$dnsout" ;;
        2)
            echo -e "DNS $WARN\n  \` $(awk '{print "'"$DNS_NDD_QUERY("'"$5"'")"'", "<->", $9}' <<< $dnsout)" ;;
    esac
}

_TLSCERT_CHECK(){
    local HOST="$1"
    local PORTS="${@:2}" ; local PORT
    local ACTUAL_TIMESTAMP=$(date +%s)
    echo -e "TLS Informations"
    for PORT in $PORTS; do
        local EXPIRE_DATE=$(echo | openssl s_client -connect "${HOST}:${PORT}" -showcerts |& openssl x509 -noout -dates 2> /dev/null| awk -F'=' '/notAfter/{print $2}')
	echo "${MARKEND}(:$PORT) -> Expire on $EXPIRE_DATE" ;
    done
    # for PORT in $PORTS {
    #    local EXPIRE_DATE=$(echo | openssl s_client -connect "${HOST}:${PORT}" -showcerts |& openssl x509 -noout -dates 2> /dev/null| awk -F'=' '/notAfter/{print $2}')
    #    echo "${MARKEND} Expire on $EXPIRE_DATE" ;
    # }
    # local EXPIRE_DATE=$(echo | openssl s_client -connect "${HOST}:${PORT}" -showcerts |& openssl x509 -noout -dates 2> /dev/null| awk -F'=' '/notAfter/{print $2}')
    # echo -e "TLS Information (:${PORT})\n${MARKEND} Expire on $EXPIRE_DATE"
}

_PLEX_CHECK(){
    local PLEXSERV="$1"
    local PLEXPORT="${2:-32400}"
    local PLEXNAME='PLEX'
    _HTTPD_CHECK "$PLEXSERV" "$PLEXPORT" "$PLEXNAME"
}

_RDP_CHECK(){
    local RDPSERV="$1"
    local RDPPORT="${2:-3389}"
    local RDPNAME="RDP"
     _NETCAT_CHECK_TEMPLATE "$RDPSERV" "$RDPPORT" "$RDPNAME"
}


[ ! -z "$1" ] && {
    . conf.rc
    H='localhost/rpi'
    host=${HOSTS[$H]}
    _PING_CHECK "$host"
    _DNS_CHECK "${host}" $DNSQUERY $DNSRESP
    _SSHD_CHECK "${host}" 22
    _HTTPD_CHECK "${host}" 80
    _RDP_CHECK "${HOSTS[ntlm]}" 3389 RDP
}

