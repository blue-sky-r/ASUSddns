#!/bin/bash

#  tail -f /var/log/syslog | ./resolve.sh | grcat /usr/share/grc/conf.log

# WAN IP
#
WAN=$( wget -q -O - ipinfo.io/ip )

[ ! $WAN ] && echo "ERR: Cannot get WAN IP !" && exit 1

# LAN
#
LAN=192.168

# Feb 10 13:55:53 gw kernel: DROP IN=ppp0 OUT= MAC= SRC=134.119.212.157 DST=95.102.107.220 LEN=447 TOS=0x00 PREC=0x00 TTL=55 ID=13765 DF PROTO=UDP SPT=5315 DPT=5060 LEN=427

# right side value from expresion 'L=R'
#
function rval
{
	local lr=$1
	echo $lr | cut -f2 -d=
}

# reverse dns lookup ip -> name
# Host 157.212.119.134.in-addr.arpa. not found: 3(NXDOMAIN)
# 220.107.102.95.in-addr.arpa domain name pointer adsl-dyn-220.95-102-107.t-com.sk.
# ;; connection timed out; no servers could be reached
# Host 34.20.93.85.in-addr.arpa not found: 2(SERVFAIL)
function ip2name
{
	local ip=$1
	host $ip | awk '/NXDOMAIN/ {print "?"} /domain name pointer/ {print $5} /connection timed out|SERVFAIL/ {print "!"}'
}

# reverse dns lookup for local LAN names
#
function local2name
{
	local ip=$1
	getent hosts $ip | awk '{print $2}'
}

# whois ip lookup to cc country code
# country:        RU
# Country:        US
# 125.139.8.26 Organization Name  : Korea Telecom
function ip2cc
{
	local ip=$1
	whois $ip | awk '/[Cc]ountry:/ {print $2}' | tail -1
}

# service/port lookup
#
function num2service
{
	local num=$1
	getent services $num | awk '{print $1}'
}

# MAIN
# ====

# read stdin
#
while read line 
do
	# split line to parts
	#
	for w in $line
	{
		echo -n "$w"
		
		case $w in
		
		SRC=$LAN.* )
			ip=$( rval $w )
			name=$( local2name $ip )
			echo -n "[$name/LAN]"
			;;
		SRC=* )
			ip=$( rval $w )
			name=$( ip2name $ip )
			cc=$( ip2cc $ip )
			echo -n "[$name/$cc]"
			;;
		DST=$WAN )
			echo -n "[WAN]"
			;;
		DST=224.0.0.1 )
			echo -n "[BCST]"
			;;
		DST=$LAN.* )
			ip=$( rval $w )
			name=$( local2name $ip )
			echo -n "[$name/LAN]"
			;;
		DST=* )
			ip=$( rval $w )
			name=$( ip2name $ip )
			cc=$( ip2cc $ip )
			echo -n "[$name/$cc]"
			;;
		DPT=* )
			port=$( rval $w )
			service=$( num2service $port )		
			echo -n "[$service]"
			;;
		SPT=* )
			port=$( rval $w )
			service=$( num2service $port )		
			echo -n "[$service]"
			;;
		* )
			;;
		esac
	
		# single space as separator
		#
		echo -n " "
	}
	
	# \n
	#
	echo

done < /dev/stdin


