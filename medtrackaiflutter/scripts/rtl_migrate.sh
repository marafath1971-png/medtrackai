#!/usr/bin/env bash
#
# rtl_migrate.sh — safe, reviewable RTL migration for MedTrack AI
#
# Converts asymmetric directional layout to logical (RTL-safe) equivalents so
# the shipped Arabic (ar) and Hebrew (he) locales render correctly. Run this
# LOCALLY where you have `flutter` + git, so you can review the diff and let the
# analyzer catch anything. It is intentionally conservative.
#
# WHY A SCRIPT INSTEAD OF HAND EDITS: the migration touches ~100 sites across
# many files. Applying it as one reviewable, git-tracked pass — with the Dart
# analyzer available — is far safer than blind manual edits.
#
# Usage:
#   ./scripts/rtl_migrate.sh          # dry run: shows every candidate line
#   ./scripts/rtl_migrate.sh --apply  # apply, then RUN `flutter analyze`
#
# After --apply ALWAYS:  dart format lib/ && flutter analyze && git diff
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LIB="$ROOT/lib"
APPLY="${1:-}"

# Only EdgeInsets.only(...) with a single left OR right (asymmetric) is unsafe.
# EdgeInsets.only(left: X, right: X) is symmetric and already RTL-safe, so we
# deliberately do NOT touch multi-arg forms here — those need human eyes.
PAT_LEFT='EdgeInsets\.only\(left:'
PAT_RIGHT='EdgeInsets\.only\(right:'
PAT_ALIGN_L='Alignment\.centerLeft'
PAT_ALIGN_R='Alignment\.centerRight'

echo "== RTL migration candidates =="
echo "-- EdgeInsets.only(left:  -> EdgeInsetsDirectional.only(start:"
grep -rnE "$PAT_LEFT" "$LIB" || true
echo "-- EdgeInsets.only(right: -> EdgeInsetsDirectional.only(end:"
grep -rnE "$PAT_RIGHT" "$LIB" || true
echo "-- Alignment.centerLeft/Right -> AlignmentDirectional.centerStart/End"
grep -rnE "$PAT_ALIGN_L|$PAT_ALIGN_R" "$LIB" || true

if [ "$APPLY" != "--apply" ]; then
  echo
  echo "Dry run only. Re-run with --apply to rewrite, then run: flutter analyze"
  exit 0
fi

echo
echo "Applying (single-arg directional only)..."
# NOTE: only rewrites the single-argument forms to stay safe.
find "$LIB" -name '*.dart' -print0 | while IFS= read -r -d '' f; do
  sed -i.bak -E \
    -e 's/EdgeInsets\.only\(left:([^,)]*)\)/EdgeInsetsDirectional.only(start:\1)/g' \
    -e 's/EdgeInsets\.only\(right:([^,)]*)\)/EdgeInsetsDirectional.only(end:\1)/g' \
    -e 's/Alignment\.centerLeft/AlignmentDirectional.centerStart/g' \
    -e 's/Alignment\.centerRight/AlignmentDirectional.centerEnd/g' \
    "$f"
  rm -f "$f.bak"
done

echo "Done. NOW RUN:"
echo "  dart format lib/ && flutter analyze && git diff"
echo "Review multi-arg EdgeInsets.only(left:.., right:..) and .fromLTRB by hand."
