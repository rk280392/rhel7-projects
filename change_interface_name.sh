#!/bin/bash
 
if [ ${UID} -ne 0 ]
then
	echo "run as sudo"
	exit 1
fi

if [ "${#}" -lt 1 ]
then
	echo "USAGE ${0} INTERFACE_NAME"
	exit 1
fi

iName=$(ip addr show | awk '/inet.*brd/{print $NF}')
macAddress=$(ip -a link show | grep -v lo | grep "\w\w:\w\w:\w\w:\w\w:\w\w:\w\w" | awk -F " " '{print $2}')
file="/etc/default/grub"
file2="/etc/sysconfig/network-scripts"

change_interface_name() {
	new_line='GRUB_CMDLINE_LINUX="crashkernel=auto rd.lvm.lv=rootvg/lv_root rd.lvm.lv=rootvg/lv_swap net.ifnames=0 biosdevname=0 rhgb quiet"'
	echo $new_line
	sed -i "s|GRUB_CMDLINE_LINUX.*|$new_line|" $file
	grub2-mkconfig -o /boot/grub2/grub.cfg
	cat <<EOF > /etc/udev/rules.d/70-persistent-net.rules
	SUBSYSTEM=="net", ACTION=="add", DRIVERS=="?*", ATTR{address}=="$macAddress", ATTR{type}=="1", KERNEL=="eth*", NAME="$1"
EOF
	cp $file2/ifcfg-$iName $file2/ifcfg-"$1"
	sed -i "s|$iName|$1|" $file2/ifcfg-"$1"  
}

change_interface_name $1

echo "Interface name changed from $iName to $1"
