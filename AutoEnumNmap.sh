#! /bin/bash
greenColour="\e[0;32m\033[1m"
endColour="\033[0m\e[0m"
redColour="\e[0;31m\033[1m"
blueColour="\e[0;34m\033[1m"
yellowColour="\e[0;33m\033[1m"
purpleColour="\e[0;35m\033[1m"
turquoiseColour="\e[0;36m\033[1m"
grayColour="\e[0;37m\033[1m"

if (("$2" = "fast")); then
	nmap -sS --min-rate 5000 --open -vvv -n -Pn -p- $1 -oG allPorts
else
	nmap -p- --open -T5 -v -n $1 -oG allPorts
fi
clear

ip_address=$(cat allPorts | grep -oP '\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}' | sort -u)
open_ports=$(cat allPorts | grep -oP '\d{1,5}/open' | cut -d "/" -f 1 | xargs | tr ' ' ',')

ttl=$(/bin/ping -c 1 $1 | grep -o 'ttl=[0-9][0-9]*' | cut -d "=" -f 2)
echo -e "$yellowColour[*] IP Address:$endColour $grayColour$ip_address$endColour"
if (("$ttl" >= "0")) && (("$ttl" <= "64")); then
    echo -e "$yellowColour[*] OS :$endColour $grayColour Linux $endColour"
elif (("$ttl" >= "65")) && (("$ttl" <= "128")); then
    echo -e "$yellowColour[*] OS :$endColour $grayColour Windows $endColour"
fi
echo -e "$yellowColour[*] Open Ports:$endColour $grayColour$open_ports$endColour\n"
echo -e "$blueColour[*] Nmap Enum Services$endColour \n"
nmap -sC -sV -p$open_ports $1 -oN targeted

web_ports=$(cat allPorts | grep -oP '\d{1,5}/open/tcp//http' | cut -d "/" -f 1 |  xargs | tr ' ' ',')
if [ -z "$web_ports" ]
then
	echo -e "$redColour\n[*] Not Find HTTP Servers$endColour\n"
else
	echo -e "$blueColour\n[*] Find HTTP Servers on Port: $web_ports$endColour\n"
    whatweb $1
	nmap -p$web_ports $1 --script http-enum -oN webScan
	wfuzz -c -t 400 --sc=200 -w /usr/share/wordlists/dirbuster/directory-list-2.3-medium.txt http://$1/FUZZ
fi



