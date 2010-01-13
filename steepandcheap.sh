#!/bin/bash

#  This program is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program.  If not, see <http://www.gnu.org/licenses/>.


# You will need to create the directory $CONF_DIR
# and the filters file $FILTERS_FILE

SAC=steepandcheap
URL=http://www.steepandcheap.com
CONF_DIR=~/.sac
WORKDIR=/tmp/$SAC
OUTPUT_FILE=$WORKDIR/$SAC.html
IMG_FILE=$WORKDIR/$SAC.item.jpg
USER_AGENT="Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.8.1.13) Gecko/20080311 Iceweasel/2.0.0.13 (Debian-2.0.0.13-0etch1)"
WGET="wget -o /dev/null --user-agent=\"$USER_AGENT\""
FILTERS_FILE=$CONF_DIR/filters

# colors
NO_COLOUR="\033[0m"
RED="\033[1;31m"
BLUE="\033[1;34m"
PURPLE="\033[1;35m"
YELLOW="\033[1;33m"


# will kill all the instances of the program
kill_all_instances()
{
	local pids=`ps fax | grep $SAC | grep -v vim | cut -d ' ' -f 1 | sort -n`
	for i in $pids
	do
		if [[ $i != $$ && $i != $PPID ]] ; then
			kill $i
		fi
	done
}

get_image()
{
	local url=`grep  "images\[1\] = .http://images.steepandcheap.com/images/items/large" $OUTPUT_FILE | cut -d '"' -f 2`
	$WGET --output-document=$IMG_FILE $url 
}

get_title()
{
	local title=`grep '<title>' $OUTPUT_FILE | cut -d '>' -f 2 | cut -d '<' -f 1 | cut -d ':' -f 2`
	echo $title
}

get_price()
{
	local price=`grep '<div id="price">' $OUTPUT_FILE | cut -d '>' -f 2 | cut -d '<' -f 1`
	echo $price
}

get_percent_off()
{
	local price=`grep '<div id="percent_off">' $OUTPUT_FILE | cut -d '>' -f 2 | cut -d '<' -f 1`
	echo $price
}

get_page()
{
	rm -f $OUTPUT_FILE 2>&1 > /dev/null
	$WGET --output-document=$OUTPUT_FILE $URL 
}

create_workdir()
{
	rm -Rf $WORKDIR
	mkdir $WORKDIR
}

print_info()
{
	local title=`get_title`
	local price=`get_price`
	local percent=`get_percent_off`
	local color_msg="$YELLOW$title $BLUE $price $NO_COLOUR $percent"
	local msg="$title $price $percent"
	clear
	if [[ $1 == "with color" ]]; then
		echo -e -n $color_msg
	else
		echo -n $msg
	fi
}

show_picture()
{
	gqview -t $IMG_FILE
}

filter_terms()
{
	local ret=0
	local title=`get_title`
	for i in `cat $FILTERS_FILE`
	do
		echo $title | grep -i $i
		if [[ -z $? ]]; then
			ret=1
		fi
	done
	return $ret
}

main()
{
	kill_all_instances
	create_workdir
	cd $WORKDIR
	local last_title=
	while [[ true ]]
	do
		get_page
		local title=`get_title`
		local time_passed=
		if [[ $last_title != $title ]]; then
			# new item
			last_title=$title
			get_image
			if [[ -z `filter_terms` ]]; then
				print_info
			else
				print_info "with color"
			fi
			local start_show=`date  +%s`
			show_picture
			local end_show=`date  +%s`
			time_passed=$((end_show-start_show))
		fi

		# sleep for random time between 60 to 120
		# if the picture took to show more then 5 minutes, then
		# we'll not sleep and go again to fetch the page
		if [[ $time_passed < $((5*60)) ]]; then
			sleep $(( 60 + $(( $RANDOM % 60 )) ))
		fi
	done
}

main
