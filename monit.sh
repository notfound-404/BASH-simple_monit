#!/bin/bash

# . <( cat ${0%/*}/{simple_curses.sh,functions.sh} )
. $PWD/conf.rc
. $PWD/simple_curses.sh
. $PWD/functions.sh

while getopts ":f:r:" OPT; do
    case $OPT in
        r)
            REFRESH_TIME="${OPTARG}" ;;
        f)
            CONFRC="${OPTARG}" ;;
        :)
            echo "Option: -$OPTARG /path/to/conf" >&2 ;;
    esac
done
# . "${0%/*}"/"${CONFRC:-conf.rc}"

# REFRESH_TIME=${REFRESH_TIME:-10}

main(){
    window "BASH monit by Notfound (refresh each ${REFRESH_TIME}sec)" "yellow"
    append "Runing on $(hostname) - $(date +"%D %T") - $(awk '{print "Load average:" $1 " " $2 " " $3}' < /proc/loadavg)" "red"
    endwin
    HOSTNAME='localhost/machine0' ; window "$HOSTNAME(${HOSTS[$HOSTNAME]})" "" "33%"
        append_command "_PING_CHECK ${HOSTS[$HOSTNAME]}"
        append_command "_HTTPD_CHECK ${HOSTS[$HOSTNAME]} $PORTHTTP"
        append_command "_DNS_CHECK ${HOSTS[$HOSTNAME]} $DNSQUERY $DNSRESP"
        append
        append_command "dfc"
	append "" ; addsep
	append "Tree files" "green" "33%" ; addsep
	if [[ -x $(which tree 2> /dev/null) ]]; then
		append_command "tree -L 1 -C -A ./"
	else
		append "Please install tree command"
	fi
	append "" ; addsep
        append "Established connexions" "green" "33%" ; addsep
	append_command "_CONNTRACK_BEAUTY_ESTABLISHED"

    endwin

col_right
set_position "$POSX" "5"
    window "VMs/CTs" "" "33%"
    HOSTNAME='machine1'; append "$HOSTNAME(${HOSTS[$HOSTNAME]})" "" "33%"
        append_command "_PING_CHECK ${HOSTS[$HOSTNAME]}"
        append_command "_SSHD_CHECK ${HOSTS[$HOSTNAME]}"
    append "" ; addsep
    HOSTNAME='machine2'; append "$HOSTNAME(${HOSTS[$HOSTNAME]})" "" "33%"
        append_command "_PING_CHECK ${HOSTS[$HOSTNAME]}"
        append_command "_RDP_CHECK ${HOSTS[$HOSTNAME]}"
    endwin

col_right
set_position "$POSX" "5"

    window "WEBSITE" "" "33%"
    HOSTNAME='www.notfound.ovh:443' ; append "$HOSTNAME (${HOSTS[$HOSTNAME]})" "" "33%"
        append_command "_PING_CHECK ${HOSTS[$HOSTNAME]}"
        append_command "_HTTPD_CHECK ${HOSTS[$HOSTNAME]} 443"
        append_command "_TLSCERT_CHECK ${HOSTS[$HOSTNAME]} 443 465 993"
        append_command "_SSHD_CHECK ${HOSTS[$HOSTNAME]} $PORTSSH"
    append "" ; addsep
    HOSTNAME='example.com:443' ; append "$HOSTNAME (${HOSTS[$HOSTNAME]})" "" "33%"
        append_command "_PING_CHECK ${HOSTS[$HOSTNAME]}"
        append_command "_HTTPD_CHECK ${HOSTS[$HOSTNAME]} $PORTHTTP"
        append_command "_SSHD_CHECK ${HOSTS[$HOSTNAME]} $PORTSSH"
    endwin

}
main_loop "$REFRESH_TIME"
