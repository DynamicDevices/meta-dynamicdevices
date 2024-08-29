  GNU nano 6.2                                                                         /usr/sbin/board_info.sh                                                                          Modified  
# Capture and display board information

MACHINE=`cat /sys/devices/soc0/machine`
SERIAL_NUMBER=`cat /sys/devices/soc0/serial_number`
WLAN_MAC=`ifconfig wlan0 | grep ether | cut -c 15-31`

MODEM_ID=` mmcli -L | cut -c 42-42`

if [ ! -z "${MODEM_ID}"	]; then
  MODEM_PRESENT="true"
  MODEM_FW=`mmcli -m ${MODEM_ID} | grep firmware | cut -c 33-48 `
  MODEM_IMEI=`mmcli -m ${MODEM_ID} | grep equipment | cut -c 33-47`
  MODEM_MSISDN=`mmcli -m ${MODEM_ID} | grep Numbers | cut -c 37-50`
  MODEM_SIM_STATE=`mmcli -m ${MODEM_ID} | grep "  state" | cut -c 26-`
else
  MODEM_PRESENT="false"
fi

echo BOARD DETAILS
echo =============
echo
echo "**************************************"
echo Machine:          $MACHINE
echo Serial:           $SERIAL_NUMBER
echo WLAN MAC:         $WLAN_MAC
echo Modem Present:    $MODEM_PRESENT
echo Modem SIM State:  $MODEM_SIM_STATE
echo Modem IMEI:       $MODEM_IMEI
echo Modem F/W:        $MODEM_FW
echo Modem MSISDN:     $MODEM_MSISDN
echo "**************************************"

echo Done
