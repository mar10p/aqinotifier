#!/bin/bash

MYPATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
source ${MYPATH}/aqinotifier.conf
date >> "${LOG}"

AQI=$(curl -s "${URL}" | ${PUP} 'p.aqi-value__value text{}' | xargs)

if [ ! "${AQI}" ]; then
  echo "FAILED to read AQI" >> "${LOG}"
  curl -s -X POST \
    -F apikey="${PROWLAPIKEY}" \
    -F application="${APPNAME}" \
    -F priority="${PRIORITY}" \
    -F url="${URL}" \
    -F event="Unable to get AQI" \
    -F description="Was not able to read the AQI from iqair.com" \
    "${PROWLURL}/add" >> "${LOG}"
  exit
fi

if [ ! -s "${STATE}" ]; then
  echo "${AQI}" > "${STATE}"
fi

STATE_DATA=$(cat "${STATE}")
PREVIOUS=$(aqimap "${STATE_DATA}")
CURRENT=$(aqimap "${AQI}")

echo "OLD AQI=${STATE_DATA}, NOW AQI=${AQI}" >> "${LOG}"

if [ "${PREVIOUS}" != "${CURRENT}" ]
then
  curl -s -X POST \
    -F apikey="${PROWLAPIKEY}" \
    -F application="${APPNAME}" \
    -F priority="${PRIORITY}" \
    -F url="${URL}" \
    -F event="AQI Change Alert" \
    -F description="AQI=${AQI}" \
    "${PROWLURL}/add" >> "${LOG}"
else
  : # Do something else, if desired
fi

echo "${AQI}" > "${STATE}"
