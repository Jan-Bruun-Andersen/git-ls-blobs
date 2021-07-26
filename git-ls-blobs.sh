#!/bin/bash

function main() # [-h | --help] [-v | --verbose ] [MODIFIERS] [repos-path ...]
#: NAME
#:   @PROG_NAME@ - Git object lister
#:
#: SYNOPSIS
#:   @PROG_USAGE@
#:
#: DESCRIPTION
#:   @PROG_NAME@ lists Git objects, optionally sorted by perm, sha1, size, or name.
#:
#: OPTIONS
#:   -h
#:       Prints a short usage text.
#:
#:   --help
#:       Prints a help text (this text).
#:
#:   -v, --verbose
#:       Display key information about the repository. Information includes:
#:       origin URL, repository type (working or bare), branch name, and
#:       the number of commits.
#:
#:       In addition, for bare Bitbucket repositories, displays
#:       Bitbucket key, ID, and repository name.
#:
#: MODIFIERS
#:
#:   -s, sort=key
#:       Select field to sort on. Possible values are: perm, sha1, size, name.
#:       The sort key can be suffixed with ':rev" to indicate reverse sorting.
#:       Default is 'size:rev'.
#:
#:   -t, top=nnn
#:       Limits the display to the top N objects.
#:
#: PARAMETERS
#:   repos-path - path to the repository
#:   
#: EXAMPLE
#:   $ @PROG_NAME@ --verbose --top=2 .
#:   Origin URL        : git@github.com:Jan-Bruun-Andersen/git-ls-blobs.git
#:   Repository type   : working
#:   Branch name       : master
#:   Number of commits : 27
#:
#:   100644 blob 99499da079cb8a71196504a919637d1e859bccc5 7 KB git-list-object-by-size.sh
#:   100644 blob aef5b2d8ff6b961c0f59500a65af166f8cb5b63f 7 KB git-list-object-by-size.sh
#:
#: EXIT STATUS
#:   0 OK
#:   2 Usage error
#:
#: SEE ALSO
#:   https://gist.github.com/magnetikonline/dd5837d597722c9c2d5dfa16d8efe5b9#file-gitlistobjectbysize-sh
#:
#: AUTHOR
#:   Jan Bruun Andersen, 2021-07-26
{
  declare -g -A REPOS_INFO
  declare -r -A sort_col=(["perm"]=1 ["sha1"]=3 ["size"]=4 ["name"]=5)
  declare       options
  declare       opt_verbose="false"
  declare	opt_sort="size:rev"
  declare       opt_top
  declare       sort_key=0
  declare	sort_modifier=
  declare    -i no=0

  options=$(getopt -o hvs:t: --long help,verbose,sort:,top: -n "${PROG_NAME}" -- "$@") || {
    printf >&2 "Usage: %s\n" "$(usage)"
    exit 2
  }

  eval set -- "${options}"
  while true; do
    case "$1" in
      -h             ) usage >&2; exit		;;
      --help         ) help  >&2; exit		;;
      -s | --sort    ) opt_sort="$2"; shift	;;
      -v | --verbose ) opt_verbose="true"	;;
      -t | --top     ) opt_top="$2"; shift	;;
      --     	     ) shift; break		;;
      *      	     ) break			;;
    esac
    shift
  done

  [[ -z "${opt_top//[0-9]/}" ]] || {
    printf >&2 "Error - illegal top value: %s. Must be numeric.\n" "${opt_top}"
    exit 2
  }

  case "${opt_sort/:rev/}" in size  ) sort_modifier="${sort_modifier}n" ;; esac
  case "${opt_sort}"       in *:rev ) sort_modifier="${sort_modifier}r" ;; esac

  sort_key="${sort_col[${opt_sort/:rev/}]}"
  if [[ ${sort_key} -eq 0 ]]; then
    declare word_list="${!sort_col[@]}"
    printf >&2 "Error - illegal sort field: %s. Valid fields are: %s\n" "${opt_sort}" "${word_list// /, }"
    exit 2
  fi

  [[ -z "$1" ]] && set -- "."

  for path in "$@"; do
    (( no+=1 ))
    REPOS_INFO=()

    [[ ${no} -gt 1 ]] && echo "---"
    if ${opt_verbose}; then
      repos_info "${path}" || continue
      echo
    fi
    list_object "${path}" "${sort_key}${sort_modifier}" "${opt_top}"
  done

  return 0
} # main()

function dump_repos_info()
{
  declare key
  for key in ${!REPOS_INFO[@]}; do
    printf "%-15s = %s\n" "${key}" "${REPOS_INFO[${key}]}"
  done
} # dump_repos_info()

###
# Executes a git command against a given directory,
#
# IMPORTANT: Older versions of git (e.g. 1.8) does not support the -C option.
#            This is a work-around where a sub-shell is used to first change
#            the working directory, run the command, and return.
#/
function git_cd() # directory git-command [parameters]
{
  : ${1:?"ERROR in function ${FUNCNAME[0]}. Parameter 1 (directory) is empty!"}
  : ${2:?"ERROR in function ${FUNCNAME[0]}. Parameter 2 (git-command) is empty!"}

  ( 
  cd "$1" || return
  shift
  git "$@"
  )
} # git_cd()

function repos_info() # repos-path
{
  : ${1:?"ERROR in function ${FUNCNAME[0]}. Parameter 1 (repos-path) is empty!"}

  get_repos_info "$1" || {
    printf >&2 "Error: Unable to get repository information from %s\n" "$1"
    return 1
  }

  # dump_repos_info
  pretty_print_repos_info '%-18s: %s\n' '  %-16s: %s\n'

} # repos_info()

###
# List Git file objects sorted by size (largest size first), optionally limited
# to X number of objects.
#
# The logic is as follows:
#
# - Get a list of all commits.
#
#   5b2c1a6cb3dabfefa9a25b38b00d9587dc2d767f
#   b1182153ff17e743efcb74ab83934faa5884102d
#   cfd75792254d3e10c6db616a3cb3a17ff05ea1a6
#   788e6329055f64c6e670767e7f5e551a56b32754
#
# - Get details about each commit.
#
#   100755 blob 53a6cc903dc7cff338e73d7cad68dc6d8cd9537b     817    files/check_bitb
#   100644 blob c38ac581e8548dc843af44f4f470a4df6d33c102    2831    files/hooks/10-whitespace
#   100644 blob 398e87fa04e998af1b9a64adb7daf4a9c0fa2cce     432    files/hooks/notify-go.sh
#
# - Eliminate all non-blob (meaning file) entries.
#
# - Sort entries according to the sort-key and de-dupe list.
#
#   100644 blob 398e87fa04e998af1b9a64adb7daf4a9c0fa2cce     432    files/hooks/notify-go.sh
#   100755 blob 53a6cc903dc7cff338e73d7cad68dc6d8cd9537b     817    files/check_bitb
#   100644 blob c38ac581e8548dc843af44f4f470a4df6d33c102    2831    files/hooks/10-whitespace
#
# - Limit output to top X entries (or all if limit is not set).
#
# - Convert the file-size (in bytes) to human-readable unit (KB, MB).
#
#   100644 blob 398e87fa04e998af1b9a64adb7daf4a9c0fa2cce     432    files/hooks/notify-go.sh
#   100755 blob 53a6cc903dc7cff338e73d7cad68dc6d8cd9537b     817    files/check_bitb
#   100644 blob c38ac581e8548dc843af44f4f470a4df6d33c102       2 KB files/hooks/10-whitespace
function list_object() # repos-path sort-key [limit]
{
  : ${1:?"ERROR in function ${FUNCNAME[0]}. Parameter 1 (repos-path) is empty!"}
  : ${1:?"ERROR in function ${FUNCNAME[0]}. Parameter 2 (sort-key) is empty!"}

  declare limit="$3"

  git_cd "$1" rev-list --all |
  while read sha1; do
    git_cd "$1" ls-tree -r --long "${sha1}"
  done |
  grep -E '^[0-9]{6} blob [0-9a-f]' |
  sort --key "$2" | uniq |
  { [[ -n "${limit}" ]] && head -"${limit}" || cat; } |
  convert_filesize
} # list_object()

###
# Returns information about the repository type.
#
# ??? pieces of information is returned:
#
# r_type - "working" or "bare"
# o_url  - Origin URL
# r_loc  - "local" or "remote"
# b_name - Branch name
# c_no   - Number of commits
# x_...  - Extra information
#/
function get_repos_info() # repos-path
{
  : ${1:?"ERROR in function ${FUNCNAME[0]}. Parameter 1 (repos-path) is empty!"}

  declare key
  declare bb_key bb_nid bb_name

  git_cd "$1" rev-parse || return

  case "$(git_cd "$1" config --get core.bare)" in
  "true"  ) REPOS_INFO["r_type"]="bare"	   ;;
  "false" ) REPOS_INFO["r_type"]="working" ;;
  esac

  REPOS_INFO["o_url"]=$( git_cd "$1" config --get remote.origin.url)
  case "$?" in
  0 ) REPOS_INFO["r_loc"]="remote" ;;
  * ) REPOS_INFO["r_loc"]="local"  ;;
  esac

  REPOS_INFO["b_name"]=$(git_cd "$1" rev-parse --abbrev-ref HEAD)
  REPOS_INFO["c_no"]=$(  git_cd "$1" rev-list  --all | wc -l    )

  if [[ -f "$1/repository-config" ]]; then
    bb_key=$(sed -n -e 's/^[[:blank:]]*project = //p'    "$1/repository-config")
    bb_nid=$(basename "$1")
    bb_name=$(sed -n -e 's/^[[:blank:]]*repository = //p' "$1/repository-config")

    REPOS_INFO["extra"]="Bitbucket:${bb_key}:${bb_nid}:${bb_name}"
  fi

  [[ -n "${REPOS_INFO["r_type"]}" ]] || return 1
  [[ -n "${REPOS_INFO["r_loc"]}"  ]] || return 1
  [[ -n "${REPOS_INFO["b_name"]}" ]] || return 1
  return 0
} # get_repos_info()

###
# Pretty-prints repository information from ${REPOS_INFO[]}.
#
# Output something like this for working repositories:
#
#   Origin URL        : git@github.com:Jan-Bruun-Andersen/git-ls-blobs.git
#   Repository type   : working
#   Branch name       : master
#   Number of commits : 26
#
# For a bare repository, in this case a Bitbucket repository, the output will
# look like this:
#
#   Repository type   : bare
#   Branch name       : HEAD
#   Number of commits : 0
#   Bitbucket key     : ~JOAPAL
#   Bitbucket ID      : 1507
#   Bitbucket name    : puppetlab
#
# @param format1
#   printf format string used when printing the 1st section with
#   Origin URL, Repository type, Branch name, and number of commits.
#   Default is '%-18s: %s\n'.
#
# @param format2
#   printf format string used when printing the 2nd section with
#   extra information.
#   Default is '%-18s: %s\n'.
#/
function pretty_print_repos_info() # [format1 [format2]]
{
  : ${1:?"ERROR in function ${FUNCNAME[0]}. Parameter 1 (format) is empty!"}

  declare fmt1="${1:-%-18s: %s\n}"
  declare fmt2="${2:-%-18s: %s\n}"

  case "${REPOS_INFO["r_loc"]}" in
  remote ) printf "${fmt1}" "Origin URL" "${REPOS_INFO["o_url"]}"	;;
  local  ) : Do nothing							;;
  *      ) printf "${fmt1}" "Remote/Local" "${REPOS_INFO["r_loc"]}"	;;
  esac

  printf "${fmt1}" "Repository type"   "${REPOS_INFO["r_type"]}"
  printf "${fmt1}" "Branch name"       "${REPOS_INFO["b_name"]}"
  printf "${fmt1}" "Number of commits" "${REPOS_INFO["c_no"]}"

  case "${REPOS_INFO["extra"]}" in
  ""          ) : Do nothing ;;
  Bitbucket:* )
    local bb_ext="${REPOS_INFO["extra"]#*:}"
    local bb_key="${bb_ext%%:*}"	; bb_ext="${bb_ext#*:}"
    local bb_nid="${bb_ext%%:*}"	; bb_ext="${bb_ext#*:}"
    local bb_nam="${bb_ext%%:*}"
    
    printf "${fmt2}" "Bitbucket key"  "${bb_key}"
    printf "${fmt2}" "Bitbucket ID"   "${bb_nid}"
    printf "${fmt2}" "Bitbucket name" "${bb_nam}"
    ;;
  * )
    printf "${fmt2}" "Extras" "${REPOS_INFO["extra"]}"
    ;;
  esac
} # pretty_print_repos_info()

###
# Converts file size into human-readable units like KB, MB, and GB.
#/
function convert_filesize()
{
  awk '
  BEGIN {
    unit[0] = " ";
    unit[1] = "K";
    unit[2] = "M";
    unit[3] = "G";
  }

  {
    u = 0; while ($4 > 1024 && unit[++u]) { $4 = int($4 / 1024); }
    $4 = sprintf("%7i %sB", $4, unit[u]);
    print;
  }
  '
} # convert_filesize()

function usage() { SL_usage; }
function help()  { SL_help;  }

source shell-lib.sh || exit
main "$@"
