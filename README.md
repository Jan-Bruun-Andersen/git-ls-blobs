# git-ls-blobs
A bash script to list git blobs optionally sorted by perm, sha1, size, or name

From the built-in help text:
```
NAME
  git-ls-blobs - Git object lister

SYNOPSIS
  git-ls-blobs [-h | --help] [-v | --verbose ] [MODIFIERS] [repos-path ...]

DESCRIPTION
  git-ls-blobs lists Git objects, optionally sorted by perm, sha1, size, or name.

OPTIONS
  -h
      Prints a short usage text.

  --help
      Prints a help text (this text).

  -v, --verbose
      Display key information about the repository. Information includes:
      origin URL, repository type (working or bare), branch name, and
      the number of commits.

      In addition, for bare Bitbucket repositories, displays
      Bitbucket key, ID, and repository name.

MODIFIERS

  -s, sort=key
      Select field to sort on. Possible values are: perm, sha1, size, name.
      The sort key can be suffixed with ':rev" to indicate reverse sorting.
      Default is 'size:rev'.

  -t, top=nnn
      Limits the display to the top N objects.

PARAMETERS
  repos-path - path to the repository

EXAMPLE
  $ git-ls-blobs --verbose --top=2 .
  Origin URL        : git@github.com:Jan-Bruun-Andersen/git-ls-blobs.git
  Repository type   : working
  Branch name       : master
  Number of commits : 27

  100644 blob 99499da079cb8a71196504a919637d1e859bccc5 7 KB git-list-object-by-size.sh
  100644 blob aef5b2d8ff6b961c0f59500a65af166f8cb5b63f 7 KB git-list-object-by-size.sh

EXIT STATUS
  0 OK
  2 Usage error

SEE ALSO
  https://gist.github.com/magnetikonline/dd5837d597722c9c2d5dfa16d8efe5b9#file-gitlistobjectbysize-sh

AUTHOR
  Jan Bruun Andersen, 2021-07-26
```
