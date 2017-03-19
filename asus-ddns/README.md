## ASUS Dynamic DNS toolkit for dd-wrt
This repository contains ASUS DDNS toolkit as command line helper scripts for handling ASUS DDNS operations like:
* registration - creating new DNS record
* checking - active DNS record verification
* updating - intelligent active DNS record update 

The main know-how comes from GIT repository Nerd based on reverse engineered some ASUS firmware. This 
 implementation does not need any external packages (like curl) to be installed. The price to pay is limited reporting
 functionality based on dd-wrt internal [wget](http://svn.dd-wrt.com/browser/src/router/busybox/networking/wget.c "wget.c source") implementation in busybox shell. 
 Despite reporting limitation this implementation supports:
  * full functionality for registering, updating and checking DNS records
  * simple installation
  * minimal network traffic footprint
  * minimal memory footprint in valuable internal flash memory
  * very efficient on router CPU, RAM (no cron jobs, etc)
  * configurable logging facility

#### ASUS DDNS
ASUS Dynamic DNS service (DDNS) is free service provided by ASUS company for most ASUS routers. The service allows you to register custom
 unique name within ASUSCOMM.COM domain, for example myhome.asuscomm.com . The registration and updates are handled seemlessly
 by ASUS original firmware. However, by installing dd-wrt you will loose all this functionality as the dd-wrt firmware is
 supporting wide range of DDNS services except ASUS DDNS. 
 
Many publicly available **DDNS** services has mixed reputation for:
 * being not reliable
 * requiring tedious registration
 * requiring frequent updates to avoid DNS record expiration
 * offering free period only for limited time
 * licensing instability etc
 * various domains
 * not limited to particular device
 
On the other hand **ASUS DDNS** service:
 * no registration required (owning qualified ASUS device is sufficient)
 * extra long DNS record expiration (based on web search over two-three years)
 * no need for frequent updates (see above)
 * reliable DNS server
 * TTL 120 sec
 * free as long as you own ASUS device
 * limited by ASUSCOMM.COM domain
 
#### Implementation
As mentioned above the dd-wrt GUI do not have any support for ASUS DDNS service. Despite having custom configuration
 for DDNS ASUS DDNS is so different so dd-wrt customization cannot be easily and efficiently used. Presented solution 
 is limited to command line only so no GUI visibility is implemeted. GUI integration would require much more internal
 dd-wrt knowledge ... 

All the communication to ASUS NS server is handled by dd-wrt built-in implemetation of [wget](http://svn.dd-wrt.com/browser/src/router/busybox/networking/wget.c "wget.c source").
 Unfortunately this dd-wrt implementation lacks of any ability to return ASUS server response code back. This choice of wget 
 eliminates the need to install external utility like curl as used in original Nerd implementation. That makes it possible 
 to use ASUS DDNS toolkit also on routers with limited free internal flash memory without active Optware ipkg packaging system. 

Due to minimize flash memory footprint only terse comments are in the script itself. The structure and variable names should
 help to self-documet the code.
 
In case of any problems please consult the section Troubleshooting. Once ASUS DDNS toolkit is setup correctly, the 
 presented solution works flawlesly as you will see bellow.

#### Installation
There are two ways to install ASUS DDNS toolkit:
* manually copy files to required locations - for advanced dd-wrt users 
* package - unpack the provided package [asus-ddns.tgz](pkg/asus-ddns.tgz "current version") (recommended way to install, assumes JFFS active)

example of installation to gateway router:

1) copy package asus-ddns.tgz to the gateway /tmp directory (or any writable dir):
```
    > scp asus-ddns.tgz gateway:/tmp/
```
  
2) login to gateway router and unpack the package: 
```
    root@gateway:/# tar zxvf /tmp/asus-ddns.tgz
    jffs/bin/
    jffs/bin/asus-ddns.sh
    jffs/etc/
    jffs/etc/config/
    jffs/etc/config/ddns.ipup
```

asus-ddns.sh is placeed to /jffs/bin ... cli script (automaticaly in PATH)
ddns.ipup is placed to /jffs/etc/config ... executed when ppp interface going up, contains just call to asus-ddns.sh
    
Alternatively ddns.ipup could be renamed to ddns.wanup (consult [dd-wrt WiKi](https://www.dd-wrt.com/wiki/index.php/Script_Execution) for details),
 but .ipup looks more appropriate (have tested both variants, they are fully functional, but like more .ipup).
     
#### Dependencies
JFFS - The installation package expects /jffs file system active on the router. JFFS has to be enabled on dd-wrt 
page **Administration / Management** in section **JFFS2**
 
![jffs](screenshots/jffs.png)

#### Usage
Execution asus-ddns.sh without any parameter shows usage help:

    usage: asus-ddns.sh [-m mac] [-i 1.2.3.4|auto] [-p PIN] [-log] (check|update|register|wget) [name]
    
    where parameters are:
    -m mac  ... optional MAC address of WAN interface (default value from nvram wan_hwaddr )
    -i ip   ... optional ip  address of WAN interface (default value from nvram wan_ipaddr )
                'auto' is to obtain ip address from external service defined in AUTO_IP (http://api.ipify.org/)
    -p pin  ... optional ASUS WPS PIN code (default value from nvram secret_code) also on ASUS sticker
    -l      ... optional logging to syslog (default to stdout)
    action  ... any action (default just print info)
                check       ... check active DNS record for name
                update      ... update active DBS record for name
                register    ... register new DNS record for name
                wget        ... troubleshooting 
    name    ... name (hostname or FQDN) for DNS record (after first successful registration optional)
    
Each parameter can be specified by one character (terse) option or by more descriptive option. The following options lines are identical:

    -m 11:22:33:44:55:66        -mac 11:22:33:44:55:66
    -i 111.222.33.44            -ip 111.222.33.44
    -p 123456                   -pin 123456 
    -l                          -log                            

All printout goes to stdout by default which is suitable for troubleshooting. Optional syslog logging is activated by
 parameter -l or -log. The order of parameters is not important. If provided more than once, the last one wins.
  
#### Register DNS record
The first time we have to register our name to create brand new DNS record. This is one time process and is the most 
 difficult step of the process due to lack of returning http code by built-in dd-wrt [wget](http://svn.dd-wrt.com/browser/src/router/busybox/networking/wget.c "wget.c source"). 

The key to successfull registration is the right selection of valid name (hostname). 

Valid DNS hostnames:
 * should contain only alpha-numeric characters
 * underscores are supported but is better to avoid them
 * hyphens are not supperted and are usualy translated
 * dots '.' are not allowed
 * should not contain national/ascented chars despite being somehow supported by many DNS servers
 * has to be unique within ASUSCOMM.COM domain
 * should be as short as possible to avoid typos
 * should be as long as needed to be unique

preferred usage (from ASUS router):

    asus-ddns.sh register myhome

explicit usage (from any other linux device):

    asus-ddns.sh -mac 11:22:33:44:55:66 -ip 111.222.33.44 -pin 123456 register myhome


#### Verify DNS record

preferred usage (from ASUS router):

    asus-ddns.sh check
    CHECK - dns.name:myname.asuscomm.com dns.ip:195.12.10.113 = wan.ip:195.12.10.113 - match OK

explicit usage  (from any other linux device):

    asus-ddns.sh -mac 11:22:33:44:55:66 -pin 123456 -ip 1.2.3.4 check myhome
    CHECK - dns.name:myname.asuscomm.com dns.ip:195.12.10.113 = wan.ip:1.2.3.4 - mismatch ERR

#### Update DNS record

Update first checks actual DNS record and executes update only if needed. This eliminates unnecessary connects
 to ASUS NS server in case of running scheduled frequent updates from cron.

preferred usage  (from ASUS router):

    asus-ddns.wrt.sh update
    UPDATE - dns.name:myname.asuscomm.com not needed as dns.ip:195.12.10.113 = wan.ip:195.12.10.113

explicit usage:

    asus-ddns.wrt.sh -mac 11:22:33:44:55:66 -pin 123456 -ip 1.2.3.4 update myhome
    UPDATE - dns.name:myname.asuscomm.com old.ip:195.12.10.113 -> new.ip:1.2.3.4
    
The ASUS NS is using TTL=120 sec. That means in average the updated record should expire from DNS cache in 60 sec. In 
 the worst case scenario the old cached record will expire in 120 sec = 2 mins. Some broken caching DNS server might 
 keep expired records longer. You can perform CHECK after update to verify that record was updated, but please consider 
 TTL and do sleep at least TTL seconds between UPDATE and CHECK to get conclusive result.

#### Troubleshooting

#### Possible problems

#### Configuration
Config values are global shell variables (You shoudn't need to touch any of these):


    # version info
    VER=2017.3
    
    # URL to retrieve wan ip if ip parameter 'auto' is specified
    AUTO_IP=http://api.ipify.org/
    
    # key to store FQDN DNS name (empty for no store functionality) 
    NVRAM_DNSNAME=wan_dnsname
    
    # ASUS domain for DynDNS service
    DOMAIN=asuscomm.com
    
    # ASUS name server for handling requests
    NS=ns1.$DOMAIN
    
    # user agent header sent with requests
    UA='ez-update-3.0.11b5 unknown [] (by Angus Mackay)'
    
    # linux wget options for trubleshooting outside of dd-wrt
    WGET_OPT='--auth-no-challenge --spider'
    
    # syslog tag
    LOG_TAG='dyndns'
    
    # default printouts to stdout
    OUT='echo'
    
    # FQDN dns_name
    DNS_NAME=${NAME%%.*}.$DOMAIN
    
    # actual ip of dns_name returned by dns resolver from ASUS name server 
    DNS_IP=$(nslookup $DNS_NAME $NS ...)
    
    # URL for GET request to register(register.jsp) or update (update.jsp) DNS record
    URL="$NS/ddns/$ACTION.jsp?hostname=$DNS_NAME&myip=$WAN_IP"


#### Cheating

#### Credits
The main credit goes to [BigNerd95](https://github.com/BigNerd95 "BigNerd95 on GitHub") for his [ASUSddns Project](https://github.com/BigNerd95/ASUSddns "ASUSddns on GitHub")

#### History
 version 2017.3 - the initial GitHub release in March 2017

**keywords**: dd-wrt, ddns, asus, RT-N16, dyndns, cli, shell, sh, busybox, dns, jffs, wan, ip

