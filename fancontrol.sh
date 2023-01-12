#!/bin/bash

COMMUNITY="YOUR_COMMUNITY"
IBMC_IP="YOUR_IBMC_IP"

CPU_TEMP="$(sensors -Aj coretemp-isa-* | jq '.[][] | to_entries[] | select(.key | endswith("input")) | .value' | sort -rn | head -n1)"

CURRENT_SPEED="$(snmpget -Oq -Ov -v2c -c $COMMUNITY $IBMC_IP .1.3.6.1.4.1.2011.2.235.1.1.8.2.0)"
CURRENT_MODE="$(snmpget -Oq -Ov -v2c -c $COMMUNITY $IBMC_IP .1.3.6.1.4.1.2011.2.235.1.1.8.1.0 | awk -F'[^0-9]+' '{ print $2 }')"

set_auto_mode() {
  if [[ $CURRENT_MODE = 1 ]]; then
    echo "Setting auto mode..."
    snmpset -v2c -c $COMMUNITY $IBMC_IP .1.3.6.1.4.1.2011.2.235.1.1.8.1.0 s "0" > /dev/null
  fi
}

set_manual_mode() {
  if [[ $CURRENT_MODE = 0 ]]; then
    echo "Setting manual mode..."
    snmpset -v2c -c $COMMUNITY $IBMC_IP .1.3.6.1.4.1.2011.2.235.1.1.8.1.0 s "1,0" > /dev/null
  fi

  if [[ $CURRENT_SPEED != $1 ]]; then
    echo "Fan adjusting at $1%."
    snmpset -v2c -c $COMMUNITY $IBMC_IP .1.3.6.1.4.1.2011.2.235.1.1.8.2.0 i $1 > /dev/null
  fi
}

if [[ $CPU_TEMP > 70 ]]; then
    set_auto_mode
elif [[ $CPU_TEMP > 65 ]]; then
    set_manual_mode 35
elif [[ $CPU_TEMP > 55 ]]; then
    set_manual_mode 30
elif [[ $CPU_TEMP > 45 ]]; then
    set_manual_mode 25
else
    set_manual_mode 20
fi
