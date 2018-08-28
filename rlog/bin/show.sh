:

tail -f /var/log/syslog | ./resolve.sh | grcat /usr/share/grc/conf.log
