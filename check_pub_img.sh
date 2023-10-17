#!/bin/bash

# if valid, return 0, otherwise return exit code 1
function check_image_link() {
	link=$1
	# use curl to check if response code not 200, return 1
	echo $link
	wget -q --max-redirect 0 -O /dev/null $link >/dev/null
	if [ $? -ne 0 ]; then
		echo "Invalid image link: $link"
		# exit with error code 1
		exit 1
	fi
}

cd content || exit

IMAGE_PATH="$(grep -R "\!\[" . | grep -v "Binary file" | cut -d ':' -f 2- | sed 's/.*(//' | sed 's/).*$//' | awk '/http/ {print $0}')"

for i in $IMAGE_PATH; do
	check_image_link $i
done
