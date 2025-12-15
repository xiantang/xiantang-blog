#!/bin/bash

# Translate markdown files that do not already have a matching .en.md sibling.
md_to_be_translated=()
while IFS= read -r path; do
	case "$path" in
		*.en.md)
			continue
			;;
		*.zh-cn.md)
			target="${path%.zh-cn.md}.en.md"
			;;
		*.md)
			target="${path%.md}.en.md"
			;;
		*)
			continue
			;;
	esac

	[[ -f "$target" ]] && continue
	md_to_be_translated+=("$path")
done < <(find ./content -type f -name '*.md')

if [[ ${#md_to_be_translated[@]} -eq 0 ]]; then
	echo "no markdown file to be translated"
	exit 0
fi

printf '%s\n' "${md_to_be_translated[@]}" | while IFS= read -r line; do
	chatgpt-md-translator -m 4 -f 1000 "$line" --out-suffix=.en.md
done
