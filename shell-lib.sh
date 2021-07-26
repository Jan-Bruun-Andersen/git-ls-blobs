function SL_init()
{
    PROG_NAME="$(basename "$0")"	; readonly PROG_NAME
}

###
# Emits a word-list in Oxford (serial) format.
#
# @param 1 Type of list, "and" or "or".
#/
function SL_word_list_ox() # {and | or} word ...
{
  local and_or=${1:?"Error in function word_list(): Parameter 1 (and_or) is empty!"}
  local sep=", "
  local wlist

  shift
  set -- $@

  while [[ -n "$1" ]]; do
    [[ -z "$2" ]] && sep=", ${and_or} "
    wlist="${wlist}${wlist:+$sep}$1"
    shift
  done
  printf "%s" "${wlist}"
} # word_list_ox()

###
# Emits a text string with the valid options and parameters for the
# main() function.
#/
function SL_usage()
{
  sed -n -e "/^function main() # /s//${PROG_NAME:?} /p" "$0"
}

###
# Emits a help text for the script by scanning for comment lines
# beginning with the magic marker '#:' located between the declaration
# of the main() function and the function body.
#/
function SL_help()
{
  sed -n -e '/^function main() # /,/^{$/s/#://p' "$0" | sed -e 's/^ //' |
  sed -e "
    s?@PROG_NAME@?${PROG_NAME}?g
    s?@PROG_USAGE@?$(usage)?g
  "
}

SL_init
