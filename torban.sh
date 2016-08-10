#!/usr/bin/env bash
#+--------+
#| TorBAN |
#+-v1.0.0-+---------+
#|Brought to you by:|
#| Shotokan@aitch.me|
#+-PGP-AHEAD--------+----------+
#|https://keybase.io/ShotokanZH|
#+-$BEGIN----------------------+

chainname="tor-ban";
token="/dev/shm/torban";		#change it to "/tmp/torban" if you don't have "/dev/shm/" in your distro
#
#Don't edit below!
#
if [ $EUID -ne 0 ];
then
	echo "[-] Not root!" >&2;
	exit 4;
fi;

if ! mkdir "$token" 2>/dev/null;	#mkdir is an atomic function
then
	echo "[-] Token found!" >&2;
	exit 1;
fi;

which iptables >/dev/null;
if [ $? -ne 0 ];
then
	PATH="$PATH:/sbin";	#cron does not have /sbin/ in $PATH
fi;

which iptables curl dig >/dev/null;
if [ $? -ne 0 ];
then
	echo -n "[-] " >&2;
	arr="iptables:iptables curl:curl dig:dnsutils";
	toi="";
	x=0;
	OFS=$IFS;
	IFS=" ";
	for a in ${arr};
	do
		app="$(echo "$a" | cut -d ":" -f 1)";
		which "$app" >/dev/null;
		if [ $? -ne 0 ];
		then
			toi="${toi}$(echo "$a" | cut -d ":" -f 2) ";
			if [ $x -gt 0 ];
			then
				echo -n ", " >&2;
			fi;
			x=$(( x + 1 ));
			echo -n "$app" >&2;
		fi;
	done;
	IFS=$OFS;
	echo " missing." >&2;
	echo "Consider running:" >&2;
	echo "sudo apt-get install ${toi}" >&2;
	rm -rf "$token";
	exit 1;
fi;

echo -n "[+] Requesting IP"
myip=$(dig +short myip.opendns.com @resolver1.opendns.com);	#you can put your static ip here in case...
if [ $? -ne 0 ];
then
	echo "";
	echo "[-] Something went wrong while requesting the current IP!" >&2;
	rm -rf "$token";
	exit 2;
fi;
echo ": $myip";

echo -n "[+] Downloading the exit nodes list..";
torlist=$(curl -s "https://check.torproject.org/cgi-bin/TorBulkExitList.py?ip=${myip}" | grep -v "#" | grep -oP "^[0-9.]+$" | sort -n);	#let's avoid strange things
if [ $? -ne 0 ];
then
	echo "";
	echo "[-] Something went wrong while requesting the tor exit nodes!" >&2;
	rm -rf "$token";
	exit 3;
fi;
echo " Done.";

iptables -w -D INPUT -j "$chainname" 2>/dev/null;	#let's avoid potential duplicates or missing redirects (or potential downtimes)

iptables -w -N "$chainname" 2>/dev/null;
if [ $? -ne 0 ];		#it's not the first time
then
	iptables -w -F "$chainname";
fi;

echo "[+] Banning tor nodes..";

iptables-save -c | grep -v "^#" | head -n -1 > "$token/ipt";

for ip in ${torlist[@]};
do
	echo -en "\r\033[K\tBanning $ip...";
	echo "[0:0] -A \"$chainname\" -s \"$ip\" -j REJECT --reject-with icmp-port-unreachable" >> "$token/ipt";
done;

echo "COMMIT" >> "$token/ipt";

echo -en "\r\033[K\tCommit...";
iptables-restore -c < "$token/ipt";

iptables -w -A "$chainname" -j RETURN;
iptables -w -I INPUT -j "$chainname";

echo "";
echo "[+] Done. (Info: iptables -L \"$chainname\" -n )";

rm -rf "$token";
