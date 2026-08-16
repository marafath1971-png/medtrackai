#!/bin/bash
# Install replacement onboarding photos.
#
# Usage:
#   tool/install_photos.sh ~/Downloads/photos
#
# Put your downloaded files in one folder, named after the slot they replace —
# e.g. ob_family.jpg, ob_rank.jpg, ob_scan.jpg. Any extension works (.jpg/.jpeg
# /.png/.webp); everything is converted to .jpg and resized to the app's budget.
# Files you have not downloaded are left untouched, so you can do this in
# batches.
#
# See PHOTO_SOURCING_BRIEF.md for what each slot should show and where to
# legally source it.

set -euo pipefail

SRC="${1:-}"
DEST="$(cd "$(dirname "$0")/.." && pwd)/assets/photos"

if [[ -z "$SRC" || ! -d "$SRC" ]]; then
  echo "usage: tool/install_photos.sh <folder-with-downloaded-photos>" >&2
  exit 1
fi

# Slot -> long edge in px. Heroes are landscape; gallery tiles are small.
HERO_PX=1600
TILE_PX=800

shopt -s nullglob nocaseglob

installed=0
for f in "$SRC"/*.{jpg,jpeg,png,webp}; do
  base="$(basename "${f%.*}")"
  target="$DEST/$base.jpg"

  if [[ ! -f "$target" ]]; then
    echo "skip   $base — no existing slot with that name"
    continue
  fi

  case "$base" in
    gallery_*) px=$TILE_PX ;;
    *)         px=$HERO_PX ;;
  esac

  before=$(stat -f%z "$target")
  # -Z preserves aspect ratio and only shrinks; -s format jpeg normalises PNG/WebP.
  sips -s format jpeg -s formatOptions 82 -Z "$px" "$f" --out "$target" >/dev/null
  after=$(stat -f%z "$target")

  note=''
  # -Z only ever shrinks dimensions, so a high-detail source can still land
  # heavier than what it replaced. Flag it rather than silently bloating the app.
  if (( after > 500*1024 )); then
    note='  <-- over 500KB, consider a simpler image'
  fi

  printf 'ok     %-22s %4dKB -> %4dKB%s\n' "$base" $((before/1024)) $((after/1024)) "$note"
  installed=$((installed+1))
done

if [[ $installed -eq 0 ]]; then
  echo "nothing installed — check filenames match the slots in assets/photos/"
  exit 1
fi

total=$(du -sk "$DEST" | cut -f1)
echo
echo "$installed photo(s) installed. assets/photos is now ${total}KB."
echo "Next: flutter clean && flutter run — then check each onboarding step."
