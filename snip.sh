#!/usr/bin/env bash

# TODO: use cache

replace_snips() {
  local source_file
  source_file="${1:?Missing source file as param}"
  local filename=${source_file##*/}
  local prefix_tmp
  prefix_tmp=$(mktemp)

  while read -r snippet; do
    echo "Downloading snippet: $snippet"
    new_file="$prefix_tmp-$((++i))-$filename"
    sed -r "\@$snippet@r"<( curl "$snippet" ) "$source_file" > "$new_file"
    source_file="$new_file"
    echo "Partial output: $source_file"
    echo
  done < <(grep -Po '(?<=snip\()[^)]+' "$source_file")

  sed 's@^[ \t]*snip@//snip@;' "$source_file" > $prefix_tmp
  rm $prefix_tmp?*
  echo "Output: $prefix_tmp"
}

replace_snips "$@"
