##!/bin/bash
md_to_be_tanslated="$({
	find ./content -type f -name '*.en.md' | sed 's/.en.md/.md/'
	find ./content -type f -name '*.md' | grep -v '.en.md'
} | sort | uniq -u)"

echo "$md_to_be_tanslated" | while read -r line; do
	echo "start to translate $line"
	chatgpt-md-translator -m 4 -f 1000 "$line" --out-suffix=.en.md

done
