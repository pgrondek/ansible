#!/usr/bin/env bash

WAN=eth0
HOSTS=(
    '1.1.1.1'
    '1.0.0.1'
    '8.8.8.8'
)
OUTLET_IP=192.168.60.14

PING_TIMEOUT=5
SOFT_WAIT_TIME=30
DHCP_WAIT_TIME=30
MODEM_RESET_WAIT_TIME=60

PING="/bin/ping -c 1 -W ${PING_TIMEOUT} -w ${PING_TIMEOUT}"
RESET_MODEM_SCRIPT="/config/scripts/tplink_smartplug.py"

DEBUG=true
DISABLE_SOFT_RESTART=true

function debug() {
    if [[ ${DEBUG} ]]; then
        echo $@
    fi
}

function soft_restart() {
    if [[ ${DISABLE_SOFT_RESTART} ]] ; then
        return
    fi

    debug "Releasing DHCP IP lease on ${WAN}"
    release dhcp interface ${WAN}

    debug "Disabling ${WAN} interface"
    set interfaces ethernet ${WAN} disable

    debug "Waiting ${SOFT_WAIT_TIME}"
    sleep ${SOFT_WAIT_TIME}

    debug "Enabling ${WAN} interface"
    set interfaces ethernet ${WAN} enable

    debug "Renewing DHCP IP lease on ${WAN}"
    renew dhcp interface ${WAN}
}

function hard_restart() {
    debug "Turning off router outlet"
    ${RESET_MODEM_SCRIPT} -t ${OUTLET_IP} -c off >> /dev/null 2>&1

    debug "Waiting ${SOFT_WAIT_TIME}"
    sleep ${SOFT_WAIT_TIME}

    debug "Turning off router outlet"
    ${RESET_MODEM_SCRIPT} -t ${OUTLET_IP} -c on >> /dev/null 2>&1
}

function ping() {
    for host in "${HOSTS[@]}"; do
        ${PING} ${host} >> /dev/null 2>&1
        if [[ $? == 0 ]] ; then
            debug "Ping successful, exiting"
            exit 0
        else
            debug "Ping failed on ${host}"
        fi
    done
}

function main() {
    ping
    soft_restart

    debug "Waiting for ip lease from dhcp (${DHCP_WAIT_TIME}s)"
    sleep ${DHCP_WAIT_TIME}

    ping
    hard_restart

    debug "Waiting for modem to bootup (${DHCP_WAIT_TIME}s)"
    sleep ${MODEM_RESET_WAIT_TIME}
    ping
    soft_restart
}

main
