#!/bin/bash

libnames=(
	"apache2"
	"libapache2-mod-php"
	"openssl"
	"p7zip-full"
	"default-jre"
	"git"
	"xvfb"
	"wkhtmltopdf"
	"postgresql")

libnamesPHP=(
	"xsl"
	"xml"
	"pgsql"
	"gd"
	"mbstring"
	"opcache")

libnamesoptional=(
	"mcrypt"
	"pdo-pgsql")

moduleapache=(
	"env_module"
	"rewrite_module"
	)

versionPHPmini=7.0

echo -e "\n----- SYSTEM REQUIRED ------ \n"

for i in "${libnames[@]}"
do
	dpkg -s $i &> /dev/null
        dpkg=$?

        if [ $dpkg -eq 0 ]; then
                echo -e "Package \e[92m\e[1m${i}\e[0m is installed"
        else
                echo -e "Package \e[91m\e[1m${i}\e[0m is NOT installed"
        fi
done

phpVersion=$(php -v | head -n 1 | cut -d " " -f 2 | cut -f1-2 -d".")

if (( $(echo "$phpVersion >= $versionPHPmini" |bc -l) ))
then
        echo -e "\nPHP VERSION : OK \n"
	echo -e "\n----- PHP REQUIRED----- \n"

	for i in "${libnamesPHP[@]}"; do
		
		dpkg --list | grep php | grep $phpVersion | grep $i &> /dev/null
		dpkg=$?

		if [ $dpkg -eq 0 ]; then
			package=$(dpkg --list | grep php | grep $phpVersion | grep $i | cut -d ' ' -f3)
			echo -e "Package \e[92m\e[1mphp-${package}\e[0m is installed"
		else
			echo -e "Package \e[91m\e[1mphp-${i}\e[0m is NOT installed"
		fi
	done

	echo -e "\n ----- PHP OPTIONAL ------ \n"

	for i in "${libnamesoptional[@]}"
	do
		if [ $i = "mcrypt" ] && (( $(echo "$phpVersion >= 7.2" |bc -l) ))
		then
			continue
		else
			dpkg --list | grep php | grep $phpVersion | grep $i &> /dev/null
			dpkg=$?

			if [ $dpkg -eq 0 ]; then
				package=$(dpkg --list | grep php | grep $phpVersion | grep $i | cut -d ' ' -f3)
				echo -e "Package \e[92m\e[1m${package}\e[0m is installed"
			else
				echo -e "Package \e[91m\e[1mphp-${i}\e[0m is NOT installed"
			fi
		fi

	done
else
	echo -e "\nPHP VERSION : KO \n"
fi

echo -e "\n----- MODULE APACHE ------ \n"

for i in "${moduleapache[@]}"
do
	apache2ctl -M 2> /dev/null | grep $i &> /dev/null
	if [ $? -eq 0 ]; then
    		echo -e "Package \e[92m\e[1m$i\e[0m is installed and activated !"
	else
		echo -e "Package \e[91m\e[1m$i\e[0m is NOT installed or NOT activated !"
	fi
done
