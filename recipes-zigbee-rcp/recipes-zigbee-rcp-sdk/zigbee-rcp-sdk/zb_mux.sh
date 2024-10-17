#!/bin/sh

soc_id=`cat /sys/devices/soc0/soc_id`

sed 's/soc_id=toConfigure/soc_id='${soc_id}'/g' -i /etc/default/zb_mux.env

case ${soc_id} in
	i.MX8MM|i.MX8MN|i.MX8MP)
		spi_dev="/dev/spidev3.0"
		int_dev="/dev/gpiochip3"
		int_line=22
		rst_dev="/dev/gpiochip1"
		rst_line=11
		;;
	i.MX93) # default config
		spi_dev="/dev/spidev0.0"
		int_dev="/dev/gpiochip5"
		int_line=10
		rst_dev="/dev/gpiochip4"
		rst_line=1
		;;
	*) # default config
		echo "unsupported platform ${soc_id}, ABORT"
		exit 1
#		spi_dev="/dev/TBD"
#		int_dev="/dev/TBD"
#		int_line=TBD
#		rst_dev="/dev/TBD"
#		rst_line=TBD
		;;
esac

# Caution: cannot create here WorkingDirectory=/var/local/zboss since it must exist before running this

# Clean WorkingDirectory
rm -f /var/local/zboss/zb_mux.log
rm -f /var/local/zboss/zb_mux.console

echo "Start ZBOSS Muxer"
/usr/sbin/zb_mux -i ${spi_dev} -o 0:/tmp/ttyOpenThread -o 2:/tmp/ttyZigbee -s -S ${spi_speed} -m 0 -I ${int_line}:${int_dev} -R ${rst_line}:${rst_dev} -t ${mux_trace}
