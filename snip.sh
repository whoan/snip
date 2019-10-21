#!/usr/bin/env bash

# TODO: use cache

source_file="${1:?Missing source file as param}"
filename=${source_file##*/}

while read -r snippet; do
  echo "Downloading snippet: $snippet"
  tmp_file="/tmp/snip-$((++i))-$filename"
  sed -r "\@$snippet@r"<( curl "$snippet" ) "$source_file" > "$tmp_file"
  source_file="$tmp_file"
  echo "Output: $source_file"
  echo
done < <(grep -Po '(?<=snip\()[^)]+' "$source_file")

sed -i 's@^[ \t]*snip@//snip@;' "$source_file"
