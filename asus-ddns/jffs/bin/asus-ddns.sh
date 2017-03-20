#!/bin/sh

# CLI version - ASUS Dynamic DNS service for dd-wrt #

# config
VER=2017.3
AUTO_IP=http://api.ipify.org/
NVRAM_DNSNAME=wan_dnsname
DOMAIN=asuscomm.com
NS=ns1.$DOMAIN
UA='ez-update-3.0.11b5 unknown [] (by Angus Mackay)'
WGET_OPT='--auth-no-challenge --spider'
LOG_TAG='dyndns'
OUT='echo'

# print/log message
msg()
{
    $OUT "$1"
}

# print msg and exit with error 255
die()
{
    msg "$1"
    exit 255
}

# usage
[ $# -lt 1 ] && die "usage: $0 [-m mac] [-i 1.2.3.4|auto] [-p PIN] [-log] (check|update|register|wget|info) [name]"

# cli pars parser
while [ $# -gt 0 ]
do
    case "$1" in
    -m|-mac)
        shift; WAN_MAC=$1
        ;;
    -i|-ip)
        shift; WAN_IP=$1
        [ "$WAN_IP" = 'auto' ] && WAN_IP=$(wget -q -O - $AUTO_IP)
        ;;
    -p|-pin)
        shift; PIN=$1
        ;;
    -l|-log*)
        OUT="logger -t $LOG_TAG"
        ;;
    *)
        [ ! $ACTION ] && ACTION=$1 && shift && continue
        NAME=$1
        ;;
    esac
    shift
done

# defaults from nvram if nvram exists
if [ $(which nvram) ]
then
    [ -z "$NAME"    ] && [ $NVRAM_DNSNAME ] && NAME=$(nvram get $NVRAM_DNSNAME)
    [ -z "$WAN_MAC" ] && WAN_MAC=$(nvram get wan_hwaddr)
    [ -z "$PIN"     ] && PIN=$(nvram get secret_code)
    [ -z "$WAN_IP"  ] && WAN_IP=$(nvram get wan_ipaddr)
fi

# basic sanity checks
[ -z "$NAME" ] && die "ERR: Invalid empty name($NAME)"
[ -z "$WAN_MAC" -o -z "$PIN" ] && die "ERR: Probabbly not ASUS router, missing wan.mac($WAN_MAC) pin($PIN)"
[ -z "$WAN_IP"  -o "$WAN_IP" = '0.0.0.0' ] && die "ERR: No connectivity to internet - wan.ip($WAN_IP)"

# FQDN dns_name
DNS_NAME=${NAME%%.*}.$DOMAIN
DNS_IP=$(nslookup $DNS_NAME $NS | awk 'res && /^Address.+([0-9]+\.){3}[0-9]+/ {print (length($2)>8)?$2:$3} /^Name.+'$DNS_NAME'/ {res=1}')

# URL for GET request to register/update operation
URL="$NS/ddns/$ACTION.jsp?hostname=$DNS_NAME&myip=$WAN_IP"

asuscom_request()
{
    wget -q -O /dev/null -U "$UA" "http://$USER:$PASS@$URL"
}

hmac_hash()
{
    echo -n $(no_dots $DNS_NAME)$(no_dots $WAN_IP) | openssl md5 -hmac $PIN 2>/dev/null | cut -d ' ' -f 2 | tr 'a-z' 'A-Z'
}

no_dots()
{
    echo "$1" | tr -d .:
}

# MAIN #

USER=$(no_dots $WAN_MAC)
PASS=$(hmac_hash)

case $ACTION in
    check)
        status='mismatch ERR'; [ "$WAN_IP" = "$DNS_IP" ] && status='match OK'
        msg "CHECK - dns.name:$DNS_NAME dns.ip:$DNS_IP = wan.ip:$WAN_IP - $status"
        ;;
    update)
        if [ "$WAN_IP" = "$DNS_IP" ]
        then
            msg "UPDATE - dns.name:$DNS_NAME not needed as dns.ip:$DNS_IP = wan.ip:$WAN_IP"
        else
            msg "UPDATE - dns.name:$DNS_NAME old.ip:$DNS_IP -> new.ip:$WAN_IP "
            asuscom_request
        fi
        ;;
    register)
        status='FAILED'
        asuscom_request && status='OK' && [ $NVRAM_DNSNAME ] && nvram set $NVRAM_DNSNAME=$DNS_NAME
        msg "REGISTER - dns.name($DNS_NAME) with dns.ip($WAN_IP) $status"
        ;;
    wget)
        msg "wget -U '$UA' $WGET_OPT 'http://$USER:$PASS@$(echo -n $URL | sed 's/wget/register/')'"
        msg "wget -U '$UA' $WGET_OPT 'http://$USER:$PASS@$(echo -n $URL | sed 's/wget/update/')'"
        ;;
    *)
        msg "INFO wan.mac($WAN_MAC) wan.ip($WAN_IP) pin($PIN) user($USER) pass($PASS)"
        ;;
esac
