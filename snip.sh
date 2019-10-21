#!/usr/bin/env bash

# TODO: use cache

_replace_snips() {
  local source_file
  source_file="${1:?Missing source file as param}"

  mapfile -t snippets < <(grep -Po '(?<=^snip\(")[^"]+' "$source_file")
  if (( ${#snippets[@]} == 0 )); then
    echo $source_file
    return
  fi

  local filename=${source_file##*/}
  local extension=${source_file##*.}
  local prefix_tmp
  prefix_tmp=$(mktemp)
  local i=0

  for snippet in "${snippets[@]}"; do
    echo "Downloading snippet: $snippet" >&2
    new_file="$prefix_tmp-$((++i))-$filename"
    sed -r "\@$snippet@r"<( curl "$snippet" ) "$source_file" > "$new_file"
    source_file="$new_file"
    echo "Partial output: $source_file" >&2
    echo >&2
  done

  local output_file=$prefix_tmp${extension:+.$extension}
  rm $prefix_tmp
  sed 's@^[ \t]*snip@//snip@;' "$source_file" > "$output_file"
  rm $prefix_tmp-*
  echo "$output_file"
}

_is_regular_file() {
  local filename
  filename=${1:?Missing filename by param}
  [ -f "$filename" ]
}

_is_text_file() {
  local filename
  filename=${1:?Missing filename by param}
  _is_regular_file "$filename" && [[ $(file -i -- "$filename" 2> /dev/null) =~ text/ ]]
}

snip() {
  declare -a params=( "$@" )
  local i
  for (( i=0; i < ${#params[@]}; ++i )); do
    # only valid files are processed
    param="${params[$i]}"
    if _is_text_file "$param"; then
      params[$i]=$(_replace_snips "$param")
    fi
  done

  echo "Execute ${params[*]}"
  echo
  "${params[@]}"
}
