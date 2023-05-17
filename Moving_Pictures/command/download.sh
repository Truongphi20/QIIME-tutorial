#!/usr/bin/bash

printarr() { declare -n __p="$1"; for k in "${!__p[@]}"; do printf "%s=%s\n" "$k" "${__p[$k]}" ; done ;  }  


access_file=$1
out_folder=$2

declare -A  access
folder_name=()

while IFS= read -r line
do
	mark=${line:0:2}
	lengh=${#line}
	if [[ $mark == "##" ]]
	then
		folder_name+=(${line:3})
		access[${line:3}]=""
	elif (( ${#line} >= 3 ))
	then
		access[${folder_name[-1]}]+=$line" " 
		
	fi

done < ${access_file}


for folder in ${folder_name[@]}
do
	mkdir $out_folder"/"$folder
	for link in ${access[$folder]}
	do
		name_file=$(echo $link | awk -F"/" '{print $NF}')
		echo "$name_file"
		wget \
			-O $out_folder"/"$folder"/"$name_file \
			"$link"
	done
done
