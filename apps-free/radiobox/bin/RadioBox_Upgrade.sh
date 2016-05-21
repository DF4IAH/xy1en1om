#!/bin/sh

echo
echo "========================================================================="
echo "Upgrading current RedPitaya image to support additional RadioBox features"
echo "========================================================================="
echo

echo
echo "Step 1: preparing kernel modules"
echo "------"
rw
mv /lib/modules /lib/modules_old
ln -s /opt/redpitaya/lib/modules /lib/modules
rm /lib/modules_old
depmod -a
echo "... done."

echo
echo "Step 2: updating the dpkg catalog"
echo "------"
rw
apt-get update -y
echo "... done."

echo
echo "Step 3: upgrade outdated packages"
echo "------"
rw
apt-get upgrade -y
echo "... done."

echo
echo "Step 4: installing additionally packages"
echo "------"
rw
apt-get -y install alsaplayer-alsa alsa-tools alsa-utils dbus dbus-x11 dosfstools esound-common flac icecast2 ices2 jack-tools locate multicat pavucontrol pulseaudio pulseaudio-esound-compat pulseaudio-module-jack python-apt rsync software-properties-common speex strace tcpdump vorbis-tools x11-common x11-xkb-utils x11-xserver-utils xauth xfonts-100dpi xfonts-75dpi xfonts-base xfonts-encodings xfonts-scalable xfonts-utils xinetd xkb-data xserver-common xserver-xorg-core
echo "... done."

echo
echo "Step 5: adding apt-repositories (PPA)"
echo "------"
rw
add-apt-repository -y ppa:kamalmostafa/fldigi
echo "... done."

echo
echo "Step 6: updating the dpkg catalog"
echo "------"
rw
apt-get update -y
echo "... done."

echo
echo "Step 7: installing additionally packages (PPA)"
echo "------"
rw
apt-get -y install fldigi flwrap
echo "... done."

#echo
#echo "Step 8: adding dpkg selections and upgrading to the current Ubuntu release."
#echo "------"
#rw
#dpkg --get-selections > data/RadioBox-Upgrade_dpkg-selections-current.dat
#LC_ALL=C cat data/RadioBox-Upgrade_dpkg-selections-needed.dat data/RadioBox-Upgrade_dpkg-selections-current.dat | grep -v deinstall | sort | uniq > data/RadioBox-Upgrade_dpkg-selections-new.dat
#dpkg --set-selections < data/RadioBox-Upgrade_dpkg-selections-new.dat
#echo "... done."

#echo
#echo "Step 9: upgrade outdates packages (2)"
#echo "------"
#rw
#apt-get upgrade -y
#echo "... done."

echo
echo "Step 10: clean-up not more needed automatic packages"
echo "-------"
rw
apt-get autoremove -y
echo "... done."

echo
echo "Step 11: clean-up packages not more needed"
echo "-------"
rw
apt-get autoclean -y
echo "... done."

echo
echo "Step 12: setting up new file links"
echo "-------"
rw
mv /etc/xinetd.conf /etc/xinetd.conf_old
mv /etc/xinetd.d    /etc/xinetd.d_old
cp -r /opt/redpitaya/etc/xinetd.conf /etc/xinetd.conf
cp -r /opt/redpitaya/etc/xinetd.d    /etc/xinetd.d
rm -rf /etc/xinetd.conf_old
rm -rf /etc/xinetd.d_old
echo "... done."

echo
echo "Step 13: setting up audio streaming"
echo "-------"
rw
addgroup --gid 115 icecast
adduser  --gecos "" --home /usr/share/icecast2 --disabled-password --disabled-login --uid 115 --gid 115 icecast2
adduser  icecast2 icecast
mv /etc/pulse    /etc/pulse_old
mv /etc/icecast2 /etc/icecast2_old
mv /etc/ices2    /etc/ices2_old 
mkdir /var/log/ices
chown -R icecast2:icecast         /var/log/ices
cp -r /opt/redpitaya/etc/pulse    /etc/pulse
cp -r /opt/redpitaya/etc/icecast2 /etc/icecast2
cp -r /opt/redpitaya/etc/ices2    /etc/ices2
chown -R icecast2:icecast /etc/icecast2 /etc/ices2
rm -rf /etc/pulse_old
rm -rf /etc/icecast2_old
rm -rf /etc/ices2_old
cp /opt/redpitaya/www/apps/radiobox/bin/data/RadioBox-Upgrade_etc_default_icecast2 /etc/default/icecast2

echo
echo "Step 14: setting up sound system"
echo "-------"
rw
redpitaya-ac97_stop
cp data/RadioBox-Upgrade_asound.state /var/lib/alsa/asound.state
redpitaya-ac97_start
alsactl restore
# amixer -D pulse sset Master 100% on
# amixer -D pulse sset Capture 100% on
# amixer -D hw:CARD=RedPitayaAC97 sset Master 100% on
# amixer -D hw:CARD=RedPitayaAC97 sset PCM 100% on
# amixer -D hw:CARD=RedPitayaAC97 sset Line 100% off
# amixer -D hw:CARD=RedPitayaAC97 sset Capture 100% on
pactl set-sink-volume 0 100%
pactl set-source-volume 1 100%
pactl set-source-output-volume 0 100%
echo "... done."

echo
echo "Step 15: update locate database"
echo "-------"
rw
updatedb
sync
ro
echo "... done."

echo
echo ">>> FINISH <<<  Congrats, the system is ready for RadioBox additional features"
echo "=============================================================================="
echo

