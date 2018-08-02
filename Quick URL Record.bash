#!/bin/bash
url_rgx='^https?://(www\.)?bbc\.co\.uk/.*/([b-df-hj-np-tv-z0-9]{8,})([/?#]|$)'
urls=()
if [[ $# -gt 0 ]]
then
	for arg in "$@"
	do
		files=()
		if [[ -d $arg ]]
		then
			echo DIR: $arg
			files=("$arg"/*.webloc)
		elif [[ -f $arg && $arg =~ \.webloc$ ]]
		then
			files=("$arg")
		fi
		for file in "${files[@]}"
		do
			echo FILE: $file
			url=
			url=$(/usr/libexec/PlistBuddy -c "Print :URL" "$file")
			if [[ $? -eq 0 && -n $url ]]
			then
				if [[ $url =~ $url_rgx ]]
				then
					echo URL: $url
					urls+=($url)
				else
					echo INVALID: $url
				fi
			fi
		done
	done
else
	read url
	if [[ -n $url ]]
	then
		echo FILE: stdin
		if [[ $url =~ $url_rgx ]]
		then
			echo URL: $url
			urls+=($url)
		else
			echo INVALID: $url
		fi
	fi
fi
for url in "${urls[@]}"
do
	[[ $url =~ $url_rgx ]]
	pid=${BASH_REMATCH[2]}
	if [[ $url =~ /ad/ ]]
	then
		pids_ad=${pids_ad:+${pids_ad},}$pid
	elif [[ $url =~ /sign/ ]]
	then
		pids_sl=${pids_sl:+${pids_sl},}$pid
	else
		pids=${pids:+${pids},}$pid
	fi
done
cmds=()
cmd_base="/usr/local/bin/get_iplayer --log-progress"
if [[ -n $pids_ad ]]
then
	cmds+=("$cmd_base --versions=audiodescribed --pid=$pids_ad")
fi
if [[ -n $pids_sl ]]
then
	cmds+=("$cmd_base --versions=signed --pid=$pids_sl")
fi
if [[ -n $pids ]]
then
	cmds+=("$cmd_base --pid=$pids")
fi
for cmd in "${cmds[@]}"
do
	echo RUN: $cmd
	$cmd
done