#!/bin/bash

set -uo pipefail


PREFIX=/opt/oai-enb
#CONFIGFILE=$PREFIX/etc/enb.conf
export CONFIGFILE=/tmp/enb.conf
export IP_ADDR=$(awk 'END{print $1}' /etc/hosts)
export IF_NAME=$(ip r | awk '/default/ { print $5 }')
cp /mnt/oai/enb.band7.tm1.50PRB.usrpb210.conf $CONFIGFILE

[ ${#MNC} == 3 ] && MNC_LEN=3 || MNC_LEN=2

sed -i 's|MNC_LEN|'$MNC_LEN'|g' $CONFIGFILE
sed -i 's|MNC|'$MNC'|g' $CONFIGFILE
sed -i 's|MCC|'$MCC'|g' $CONFIGFILE
sed -i 's|OAI_ENB_IF|'$IF_NAME'|g' $CONFIGFILE
sed -i 's|OAI_ENB_IP|'$OAI_ENB_IP'|g' $CONFIGFILE
sed -i 's|MME_IP|'$MME_IP'|g' $CONFIGFILE

echo "=================================="
echo "/proc/sys/kernel/core_pattern=$(cat /proc/sys/kernel/core_pattern)"

if [ ! -f $CONFIGFILE ]; then
  echo "No configuration file found: please mount at $CONFIGFILE"
  exit 255
fi

echo "=================================="
echo "== Configuration file:"
cat $CONFIGFILE

# Load the USRP binaries
echo "=================================="
echo "== Load USRP binaries"
if [[ -v USE_B2XX ]]; then
    $PREFIX/bin/uhd_images_downloader.py -t b2xx
elif [[ -v USE_X3XX ]]; then
    $PREFIX/bin/uhd_images_downloader.py -t x3xx
elif [[ -v USE_N3XX ]]; then
    $PREFIX/bin/uhd_images_downloader.py -t n3xx
fi

# enable printing of stack traces on assert
export OAI_GDBSTACKS=1

echo "=================================="
echo "== Starting eNB soft modem"
if [[ -v USE_ADDITIONAL_OPTIONS ]]; then
    echo "Additional option(s): ${USE_ADDITIONAL_OPTIONS}"
    new_args=()
    while [[ $# -gt 0 ]]; do
        new_args+=("$1")
        shift
    done
    for word in ${USE_ADDITIONAL_OPTIONS}; do
        new_args+=("$word")
    done
    echo "${new_args[@]}"
    exec "${new_args[@]}"
else
    echo "$@"
    exec "$@"
fi
