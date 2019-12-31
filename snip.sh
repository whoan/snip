#!/usr/bin/env bash

__snip__remove_snip_lines() {
  local source_file
  source_file="${1:?Missing source file as param}"
  sed '/^[^[:alnum:]]*snip[^[:alnum:]]*"/d' "$source_file"
}


__snip__get_setting() {
  local repo=https://github.com/whoan/snip
  local setting_key
  setting_key=${1:?You need to specify a setting}

  local config_file=~/.config/snip/settings.ini
  if [ ! -f "$config_file" ]; then
    mkdir -p "${config_file%/*}" && touch "$config_file"
  fi

  local setting_value
  setting_value=$(grep -Po "(?<=^$setting_key=).+" "$config_file")
  if [ -z "$setting_value" ]; then
    echo "You need to set '$setting_key' in $config_file -> More info: $repo" >&2
    return 1
  fi

  echo "$setting_value"
}


__snip__fix_home_directory() {
  local param
  param=${1:?Missing param}
  if [[ $param =~ ^~/ ]]; then
    echo ${param/\~/$HOME}
  else
    echo $param
  fi
}


__snip__is_local_snippet() {
  local snippet
  snippet="${1:?Missing snippet as param}"
  [[ $snippet =~ ^(\.|~|/) ]]
}


__snip__get_snippet_url() {
  local snippet
  snippet="${1:?Missing snippet as param}"

  # snippet is already fully qualified, nothing else to do
  if [[ $snippet =~ ^http ]]; then
    echo "$snippet"
    return 0
  fi

  local base_url
  base_url=$(__snip__get_setting base_url) || return 1
  echo "${base_url%/}/$snippet"
}


__snip__curl_http_error() {
  local content_file
  content_file=${1:?Please provide the retrieved content by curl}
  local status_code
  status_code=${2:?Please provide an HTTP status code}
  [[ $(cut -f1 -d: "$content_file") == "$status_code" ]]
}


__snip__create_hash() {
  local input
  input=${1:?You must provide an input string to hash}
  echo -ne "$input" | md5sum | cut -d' ' -f1
}


__snip__download_snippet() {
  local snippet_url
  snippet_url=${1:?Please provide a url where to download snippet from}
  local snippet_file
  snippet_file=${2:?Please provide the name of the cached snippet file}
  local force=$3

  if [[ $force == 1 || ! -f "$snippet_file" ]]; then
    echo "Downloading snippet: $snippet_url" >&2
    curl --silent "$snippet_url" -o "$snippet_file"
    if __snip__curl_http_error "$snippet_file" 404; then
      echo "Error downloading snippet: $snippet_url" >&2
      return 1
    fi
  fi
}

__snip__check_too_many_replacements() {
  if (( ++__snip_replacements > 20 )); then
    echo "Too many snip replacements." >&2
    echo "Please check your code for cyclic dependencies or open an issue: https://github.com/whoan/snip/issues/new" >&2
    return 1
  fi
}

__snip__replace_snips() {
  local source_file
  source_file="${1:?Missing source file as param}"
  local force
  force=$2

  # get snippet urls/paths with line numbers as a prefix
  mapfile -t snippets < <(grep -nPo '(?<=(^|(?<![[:alnum:]]))snip)[^[:alnum:]]*"[^"]+' "$source_file")
  local n_snippets=${#snippets[@]}
  if (( n_snippets == 0 )); then
    echo $source_file
    return
  fi
  # remove leading characters taken by grep
  snippets=( "${snippets[@]//:[^[:alnum:]]*\"/:}" )

  __snip__check_too_many_replacements || return 1

  local filename=${source_file##*/}
  local root_filename="${filename%.*}"
  local extension="${filename#"$root_filename"}"

  # remove old snip tmp files
  # using --dry-run is unsafe. not doing so, we also test access to tmp filesystem. see man mktemp
  local tmp_file
  tmp_file=$(command -p mktemp -t snip.XXXXXX) || return 1
  rm "${tmp_file%/*}"/snip.*

  # show proper number of line and filename on c/c++ compilation errors
  cp "$source_file" "$tmp_file"
  if __snip__is_c_or_cpp_file "$source_file"; then
    __snip__process_c_or_cpp_file "$source_file" "$tmp_file" "${snippets[@]}" || return 1
  fi
  source_file=$tmp_file

  local cache_dir=~/.cache/snip
  mkdir -p "$cache_dir"/

  local i
  for ((i=0; i < n_snippets; ++i)); do
    local snippet="${snippets[$i]/*:/}"

    local snippet_file
    if __snip__is_local_snippet "$snippet"; then
      snippet_file=$(__snip__fix_home_directory "$snippet")
    else
      # get full url of the snippet
      local snippet_url
      snippet_url=$(__snip__get_snippet_url "$snippet") || return 1

      # download snippet if necessary
      snippet_file=$cache_dir/$(__snip__create_hash "$snippet_url")
      if ! __snip__download_snippet "$snippet_url" "$snippet_file" $force; then
        rm -f "$snippet_file"
        return 1
      fi
    fi

    # replace snips recursively
    local recursive_snippet_file
    recursive_snippet_file=$(__snip__replace_snips "$snippet_file" $force) || return 1
    local new_file=$tmp_file-$i--$filename
    sed -r "\@$snippet@r"<( cat "$recursive_snippet_file" ) "$source_file" > "$new_file" || return 1
    source_file="$new_file"
  done

  local output_file=${tmp_file}-output${extension}
  __snip__remove_snip_lines "$source_file" > "$output_file"
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


__snip__is_c_or_cpp_file() {
  local filename
  filename=${1:?Missing filename by param}
  [[ $(file -i -- "$filename" 2> /dev/null) =~ text/x-c[\+\;] ]]
}


__snip__process_c_or_cpp_file() {
  local source_file
  source_file=${1:?Missing source file as param}
  shift
  local tmp_file
  tmp_file=${1:?Missing tmp file as param}
  shift
  : ${1:?Missing snippets as params}

  sed -i.bak \
    "1i #line 1 \"$source_file\"" \
    "$tmp_file" || return 1

  local snippet
  for snippet in "$@"; do
    sed -i.bak \
      -e "${snippet/:*/}i #line 1 \"${snippet/*:/}\"" \
      -e "${snippet/:*/}a #line $((${snippet/:*/} + 1)) \"$source_file\"" \
      "$tmp_file" || return 1
  done
}


__snip__can_run() {

  if (( ${#@} == 0 )) || [[ $1 == '-h' ]] || [[ $1 == '--help' ]]; then
    cat >&2 <<EOF
Usage: snip [options] <arguments...>
Options:
  -h, --help    This help
  -f, --force   Force to download content from url bypassing (and updating) cache

Example:
  snip gcc source_file_with_snips.c  # more examples: https://github.com/whoan/snip/blob/master/readme.md
EOF
    return 1
  fi

  if ! which curl > /dev/null 2>&1; then
    echo "You need 'curl' to run this script" >&2
    return 1
  fi

  # alpine does not include file by default
  if ! which file > /dev/null 2>&1; then
    echo "You need 'file' command to run this script" >&2
    return 1
  fi
}


__snip() {
  __snip__can_run "$@" || return 1

  local force
  if [[ $1 == '-f' || $1 == '--force' ]]; then
    force=1
    shift
  fi

  declare -a params=( "$@" )
  local i
  for (( i=0; i < ${#params[@]}; ++i )); do
    # only valid files are processed
    local param="${params[$i]}"
    if __snip__is_text_file "$param"; then
      __snip_replacements=0
      params[$i]=$(__snip__replace_snips "$param" $force) || return 1
    fi
  done

  echo "Running: ${params[*]}" >&2
  "${params[@]}"
}
