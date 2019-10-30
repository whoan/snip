#!/usr/bin/env bash

__snip__remove_snip_line() {
  local source_file
  source_file="${1:?Missing source file as param}"
  sed "/^[ \t]*snip/d" "$source_file"
}

__snip__replace_snips() {
  local source_file
  source_file="${1:?Missing source file as param}"

  mapfile -t snippets < <(grep -Po '(^|(?<=[^[:alnum:]]))(?<=snip\(")[^"]+' "$source_file")
  if (( ${#snippets[@]} == 0 )); then
    echo $source_file
    return
  fi

  local filename=${source_file##*/}
  local root_filename="${filename%.*}"
  local extension="${filename#"$root_filename"}"
  local prefix_tmp
  prefix_tmp=$(mktemp)
  local i=0
 
  mkdir -p ~/.cache/snip/

  for snippet in "${snippets[@]}"; do
    sniphash=$(echo -ne $snippet|md5sum|cut -d' ' -f1)
    new_file=$prefix_tmp-$((++i))-$filename
    if [ ! -f ~/.cache/snip/${sniphash} ];then
	echo "Downloading snippet: $snippet" >&2
	curl "$snippet"	> ~/.cache/snip/${sniphash} 2> /dev/null 
    fi
    sed -r "\@$snippet@r"<( cat ~/.cache/snip/${sniphash} 2> /dev/null ) "$source_file" > "$new_file" || return 1
    source_file="$new_file"
    echo >&2
  done

  local output_file=${prefix_tmp}${extension}
  rm $prefix_tmp
  __snip__remove_snip_line "$source_file" > "$output_file"
  rm $prefix_tmp-*

  echo "$output_file"
}

__snip__is_regular_file() {
  local filename
  filename=${1:?Missing filename by param}
  [ -f "$filename" ]
}

__snip__is_text_file() {
  local filename
  filename=${1:?Missing filename by param}
  __snip__is_regular_file "$filename" && [[ $(file -i -- "$filename" 2> /dev/null) =~ text/ ]]
}

snip() {
  declare -a params=( "$@" )
  local i
  for (( i=0; i < ${#params[@]}; ++i )); do
    # only valid files are processed
    param="${params[$i]}"
    if __snip__is_text_file "$param"; then
      params[$i]=$(__snip__replace_snips "$param") || return 1
    fi
  done

  echo "Running: ${params[*]}" >&2
  echo >&2
  "${params[@]}"
}
