#!/bin/bash

# Translate markdown files that do not have a matching .en.md sibling
# or whose Chinese source was updated more recently (by lastmod or mtime).
PYTHON_BIN="$(command -v python3 || command -v python)"
if [[ -z "$PYTHON_BIN" ]]; then
	echo "python3 or python is required to parse lastmod timestamps" >&2
	exit 1
fi

extract_lastmod() {
	local file="$1"
	awk '
		/^---/ { front++ }
		front==1 && /^lastmod:[[:space:]]*/ {
			sub(/^lastmod:[[:space:]]*/, "", $0)
			print
			exit
		}
	' "$file"
}

to_epoch() {
	local ts="$1"
	"$PYTHON_BIN" - "$ts" <<'PY'
import sys
from datetime import datetime, timezone

value = sys.argv[1]
for fmt in ("%Y-%m-%dT%H:%M:%S%z", "%Y-%m-%dT%H:%M:%S", "%Y-%m-%d"):
    try:
        dt = datetime.strptime(value, fmt)
        if dt.tzinfo is None:
            dt = dt.replace(tzinfo=timezone.utc)
        print(int(dt.timestamp()))
        sys.exit(0)
    except Exception:
        continue
sys.exit(1)
PY
}

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

	# translate when English file is missing
	if [[ ! -f "$target" ]]; then
		md_to_be_translated+=("$path")
		continue
	fi

	# compare lastmod; fall back to mtime when unavailable or unparsable
	src_lastmod=$(extract_lastmod "$path")
	tgt_lastmod=$(extract_lastmod "$target")
	if [[ -z "$src_lastmod" && -z "$tgt_lastmod" ]]; then
		continue
	fi
	if [[ -n "$src_lastmod" && -n "$tgt_lastmod" ]]; then
		src_epoch=$(to_epoch "$src_lastmod" || true)
		tgt_epoch=$(to_epoch "$tgt_lastmod" || true)
		if [[ -n "$src_epoch" && -n "$tgt_epoch" ]]; then
			if [[ "$src_epoch" -gt "$tgt_epoch" ]]; then
				md_to_be_translated+=("$path")
			fi
			continue
		fi
	fi

	if [[ "$path" -nt "$target" ]]; then
		md_to_be_translated+=("$path")
	fi
done < <(find ./content -type f -name '*.md')

if [[ ${#md_to_be_translated[@]} -eq 0 ]]; then
	echo "no markdown file to be translated"
	exit 0
fi

printf '%s\n' "${md_to_be_translated[@]}" | while IFS= read -r line; do
	chatgpt-md-translator -m 4 -f 1000 "$line" --out-suffix=.en.md
done
