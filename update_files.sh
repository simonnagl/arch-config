#!/bin/sh
# Usage: update_files.sh [Option]... check|out|in
# 
# Check for changes of gatherd configuration files or
# updates them.
#
# Optionen:
# 	-c [FILE]	FILE with a path list of configuration files
# 	-f [FILE]	Only check or update FILE
# 	-h			Print thus usage
# 
# check: report which global files differ their gatherd files
# out: update global configuration files to fit gathered files
# in: update gathered files to fit global configuration files.



# Set default options
file_path_list='file_path_list'; # -c
only_update_file=''; # -f
config_files_folder_rel_to_script='config_files'
decree='';



##### START FUNCTIONS #####

# exit_ifn_cmdarg ARGUMENT
# exit if ARGUMENT is nor a string or starting with '-'
exit_ifn_cmdarg() {
	if [ -z "$1" -o "-" = `echo "$1" | cut -b 1` ]
	then
		echo "Error: A command line option needs an argument"
		print_usage
		exit 1;
	fi
}

# Print usage from the head of the file
print_usage() {
	sed -n '/^$/q; /# /s/# //p' "$0"
}

run() {
	gatherd_filename=`dirname $0`/$config_files_folder_rel_to_script/`basename $current_filename`
	case $decree in
		"check")
			run_check
			;;
		"out")
			run_out
			;;
		"in")
			run_in
			;;
	esac
}
run_check() {

	if ! diff $current_filename $gatherd_filename > /dev/null
	then
		#TODO Add a description where the file changed
		echo "$current_filename has changed somwhere"
	fi
}
run_out() {
	echo "update $current_filename"
	# TODO: Run with sudo if required
	cp $gatherd_filename $current_filename
}
run_in() {
	echo "refresh $current_filename"
	cp $current_filename $gatherd_filename
}



##### START MAIN SCRIPT #####

# Parse command line arguments
while [ $# -gt 0 ] 
do
	case "$1" in
		-c)
			shift;
			exit_ifn_cmdarg $1
			file_path_list="$1"
			;;
		-f) 
			shift;
			exit_ifn_cmdarg $1
			only_update_file="$1"
			;;
		'check' | 'out' | 'in')			
			decree=$1
			;;
		-h)
			print_usage
			exit 0
			;;
		*)  
			echo "Error while parsing command line"
			print_usage
			exit 1
			;;
	esac
	shift
done
# Check if decree was set
if [ $decree = '' ] 
then
	echo "Error while parsing command line. Read usage and try again."
	print_usage
	exit 1
fi

# Check if only_update_file is set.
if [ -z $only_update_file ]
then
	# If not, parse file_path_list and procese decree for every line
	while read line           
	do           
		if [ ! -z $line ]
		then
			current_filename=$line
			run
		fi
	done <$file_path_list
else
	# If yes, process decree for it.
	current_filename=$only_update_file
	run
fi
