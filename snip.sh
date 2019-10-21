#!/usr/bin/env bash

# TODO: use cache

replace_snips() {
  local source_file
  source_file="${1:?Missing source file as param}"
  local filename=${source_file##*/}
  local extension=${source_file##*.}
  local prefix_tmp
  prefix_tmp=$(mktemp)

  while read -r snippet; do
    echo "Downloading snippet: $snippet" >&2
    new_file="$prefix_tmp-$((++i))-$filename"
    sed -r "\@$snippet@r"<( curl "$snippet" ) "$source_file" > "$new_file"
    source_file="$new_file"
    echo "Partial output: $source_file" >&2
    echo >&2
  done < <(grep -Po '(?<=^snip\()[^)]+' "$source_file")

  output_file=$prefix_tmp${extension:+.$extension}
  rm $prefix_tmp
  sed 's@^[ \t]*snip@//snip@;' "$source_file" > "$output_file"
  rm $prefix_tmp-*
  echo "$output_file"
}

replace_snips "$@"
