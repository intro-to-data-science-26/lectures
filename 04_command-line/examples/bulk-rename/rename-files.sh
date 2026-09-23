#!/bin/sh
# Clean up messy filenames in messy/: lowercase everything, replace spaces
# with dashes, and drop awkward characters like (), !.
#   "Final Report VERSION 2 (copy).docx" -> "final-report-version-2-copy.docx"
#
# SAFE BY DEFAULT: running ./rename-files.sh only *prints* what would happen
# (a dry run). Run ./rename-files.sh --apply to actually rename.

cd messy || exit 1

for f in *
do
  # skip anything that isn't a regular file (just in case)
  [ -f "$f" ] || continue

  clean=$(printf '%s' "$f" \
    | tr '[:upper:]' '[:lower:]' \
    | tr ' ' '-' \
    | tr -d '()!' \
    | tr -s '-')

  [ "$f" = "$clean" ] && continue   # nothing to do

  if [ "$1" = "--apply" ]
  then
    mv -i "$f" "$clean" && echo "renamed: $f -> $clean"
  else
    echo "would rename: $f -> $clean"
  fi
done

[ "$1" = "--apply" ] || echo "
(dry run only -- rerun with --apply to rename for real)"
