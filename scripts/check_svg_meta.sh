#!/bin/bash

err=0
arg_fix=0

for arg in "$@"
do
	if [ "$arg" == "--help" ] || [ "$arg" == "-h" ] || [ "$arg" == "help" ]
	then
		echo "usage: $(tput bold)$(basename "$0") [OPTION]$(tput sgr0)"
		echo "options:"
		echo "  --help|-h       show this help"
		echo "  --fix|-f        automatically fix files"
		exit 0
	elif [ "$arg" == "--fix" ] || [ "$arg" == "-f" ]
	then
		arg_fix=1
	else
		echo "unkown option $arg try --help"
		exit 1
	fi
done

while IFS= read -r file
do
	if [ "$arg_fix" == "1" ]
	then
		sed -i -r '/export-filename="([A-Z]:|\/)/d' "$file"
		continue
	fi
	while IFS= read -r line
	do
		printf "[-] ERROR: absolute export path found in %s:%d\\n" \
			"$file" \
			"$(echo "$line" | cut -d':' -f1)"
		err="$((err+1))"
	done < <(grep -nE 'export-filename="([A-Z]:\\|/)' "$file")

	# check if there is width and height parameter
	width_found=$(grep -Eiwzo "<svg[^>]*>" "$file" | tr '\0' '\n' | grep -Eo "width=\"([0-9.]|px)*\"")
	height_found=$(grep -Eiwzo "<svg[^>]*>" "$file" | tr '\0' '\n' | grep -Eo "height=\"([0-9.]|px)*\"")

	if [[ "$width_found" == "" || "$height_found" == "" ]]
	then
		printf "[-] ERROR: no width or height parameter found in %s\\n" "$file"
		err="$((err+1))"
	fi
	if grep -qF 'xlink:href="data:image/png;base64,' "$file"
	then
		printf "[-] ERROR: embedded image found %s\\n" "$file"
		err="$((err+1))"
	fi
done < <(find . -type f -name "*.svg")

if [ "$err" -ne "0" ]
then
	echo "[-] failed ($err errors)"
	exit 1
fi

echo "[+] done"

