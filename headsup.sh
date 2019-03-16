# !/bin/bash

curver=$(grep 'game_version' /opt/factorio/player-data.json| cut -c 22-27)
echo 'Currently installed version: '$curver

if [ $# -eq 0 ]; then 
	printf 'No argument specified, quitting...\n OPTIONS:\n [-x] to parse experimental\n [-s] to parse stable\n [-v] to install specific version\n'
	exit
fi

while getopts ":xshv:" opt;  do
	case $opt in 
		x)
			release='latest'
			;;
		s)
			release='stable'
			;;
		h)
			printf 'A simple script to parse and update a local factorio headless server\n MUST BE RUN AS ROOT\n Options:\n	[-s] install latest stable version\n	[-x] install latest experimental version\n	[-v] $VERSION install specified version\n	[-h] display this message\n'
			exit 
			;;
		v)
			if [[ ${OPTARG} =~ ^[0-9]{1}.[0-9]{2}.[0-9]{1,2}$ ]]; then
				getver=${OPTARG}
			else
				printf 'Invalid version number:\nPlease input a three element version number\nEX: #.##.##\n'
				exit 1
			fi
			;;
		\?)
			echo "Invalid argument, quitting..."
			exit 1
			;;
		:)
			echo "No version number given, quitting..."
			exit 1
			;;
	esac
done

function version { echo "$@" | awk -F. '{ printf("%d%03d%03d%03d\n", $1,$2,$3,$4); }'; }

if [ -z $getver ]; then 
	getver=$(curl -s "https://www.factorio.com/get-download/${release}/headless/linux64" | grep -Po -m 1 "(\d+\.+\d+\.+\d+)" | head -1)
fi
if [ -z $release ] || [[ "$release" = "stable" ]]; then
	if [ "$(version "$curver")" -lt "$(version "$getver")" ]; then
		grade='Up'		
	elif [ "$(version "$curver")" -gt "$(version "$getver")" ]; then
		grade='Down'
	fi
	read -p $grade'grade to '$getver'? [y/N] : ' -n 1 -r
	echo ""
else
	if [ "$(version "$curver")" -lt "$(version "$getver")" ]; then
		printf 'New version available for install:\n '$curver' > '$getver'\n'
		read -p "Install now? [y/N] : " -n 1 -r 
		echo ""
	elif [ "$(version "$curver")" -gt "$(version "$getver")" ]; then
		printf 'Latest version already installed\n	quitting...\n'
		exit
	fi
fi
if  [[ $REPLY =~ ^[Yy]$ ]]; then
	rm -f /tmp/linux64*
	if [ -z $release ]; then
		wget --show-progress -P /tmp/ "https://www.factorio.com/get-download/${getver}/headless/linux64"
	else 
		wget --show-progress -P /tmp/ "https://www.factorio.com/get-download/${release}/headless/linux64"
	fi
	if [[ $? -gt 1 ]]; then
		printf 'Unable to download, quitting...\n'
		exit 1
	fi
	tar -xJf /tmp/linux64 --directory /opt/ -v
	if [[ $? != 0 ]]; then
		printf 'Extraction failed, quitting...\n'
		exit
	fi
	rm -f /tmp/linux64*
	printf 'Sucessfully installed version '$getver'\n'
elif [[ ! $REPLY =~ ^[Yy]$ ]]; then
	[[ "$0" = "$BASH_SOURCE" ]] && exit 1 || return 1
fi

