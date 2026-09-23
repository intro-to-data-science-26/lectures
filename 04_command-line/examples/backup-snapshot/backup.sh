#!/bin/sh
# Create a dated zip snapshot of a folder and keep only the 5 newest backups.
# Usage: ./backup.sh [folder-to-back-up]   (default: ../meals)
# Rerun it a few times to see the retention rule kick in.

TARGET="${1:-../meals}"
STAMP=$(date +%Y-%m-%d_%H%M%S)
ARCHIVE="backups/backup-$STAMP.zip"

[ -d "$TARGET" ] || { echo "No such folder: $TARGET"; exit 1; }

mkdir -p backups
zip -qr "$ARCHIVE" "$TARGET" &&
  echo "created $ARCHIVE ($(du -h "$ARCHIVE" | cut -f1))"

# Retention: list backups newest-first, skip the first 5, delete the rest
ls -t backups/backup-*.zip | tail -n +6 | while read -r old
do
  rm "$old" && echo "removed old backup: $old"
done

echo ""
echo "Current snapshots:"
ls -lht backups
