#!/usr/bin/env bash

# TODO: use cache

_replace_snips() {
  local source_file
  source_file="${1:?Missing source file as param}"
  local filename=${source_file##*/}
  local extension=${source_file##*.}
  local prefix_tmp
  prefix_tmp=$(mktemp)

  local i=0
  while read -r snippet; do
    echo "Downloading snippet: $snippet" >&2
    new_file="$prefix_tmp-$((++i))-$filename"
    sed -r "\@$snippet@r"<( curl "$snippet" ) "$source_file" > "$new_file"
    source_file="$new_file"
    echo "Partial output: $source_file" >&2
    echo >&2
  done < <(grep -Po '(?<=^snip\()[^)]+' "$source_file")

  local output_file=$prefix_tmp${extension:+.$extension}
  rm $prefix_tmp
  sed 's@^[ \t]*snip@//snip@;' "$source_file" > "$output_file"
  rm $prefix_tmp-*
  echo "$output_file"
}

snip() {
  declare -a params=( "$@" )
  local i
  for (( i=0; i < ${#params[@]}; ++i )); do
    # only valid files are processed
    if ! [ -f "${params[$i]}" ] || ! [[ $(file -i -- "${params[$i]}" 2> /dev/null) =~ text/plain ]]; then
      continue
    fi
    params[$i]=$(_replace_snips "${params[$i]}")
  done

  echo "Execute ${params[*]}"
  "${params[@]}"
}
