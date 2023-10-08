#!/bin/bash
md_to_be_tanslated="$({
	find ./content -type f -name '*.en.md' | sed 's/.en.md/.md/'
	find ./content -type f -name '*.md' | grep -v '.en.md'
} | sort | uniq -u)"
# check is empty
if [[ -z $md_to_be_tanslated ]]; then
	echo "no markdown file to be translated"
	exit 0
fi

echo "$md_to_be_tanslated" | while read -r line; do
	chatgpt-md-translator -m 4 -f 1000 "$line" --out-suffix=.en.md
done
