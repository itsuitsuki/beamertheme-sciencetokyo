#!/usr/bin/env bash
# Copy the logos and background images out of the official Science Tokyo PowerPoint templates into img/.
#
# Usage:
#   ./extract_pptx_images.sh TEMPLATE.pptx [TEMPLATE.pptx ...]
#
# Arguments:
#   TEMPLATE.pptx  One or more of the templates A to D. The variant is read from the name of the title slide layout, so the file names do not matter.
#
# Behavior:
#   Writes img/sciencetokyo-logo-{wide,stacked}.png, img/sciencetokyo-title-<variant>.{jpg,png}, and img/sciencetokyo-section-{strong,pale}-<variant>.jpg.
set -euo pipefail

if [[ $# -eq 0 ]]; then
  sed -n '2,11p' "$0" | sed 's/^# \{0,1\}//' >&2
  exit 1
fi

outdir="$(cd "$(dirname "$0")" && pwd)/img"
mkdir -p "$outdir"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

# Prints the media files that a slide layout refers to, one per line.
layout_media() {
  grep -o 'Target="../media/[^"]*"' "$tmp/ppt/slideLayouts/_rels/slideLayout$1.xml.rels" | sed 's#Target="../media/##; s#"$##'
}

# Copies a media file to img/sciencetokyo-<name>.<ext>, writing .jpeg as .jpg.
copy_media() {
  local src="$tmp/ppt/media/$1" ext="${1##*.}"
  [[ "$ext" == jpeg ]] && ext=jpg
  rm -f "$outdir/sciencetokyo-$2".{png,jpg}
  cp "$src" "$outdir/sciencetokyo-$2.$ext"
  echo "  sciencetokyo-$2.$ext"
}

for pptx in "$@"; do
  rm -rf "${tmp:?}"/*
  unzip -q -o "$pptx" 'ppt/slideLayouts/*' 'ppt/media/*' -d "$tmp"
  variant="$(grep -o '[A-D]-タイトルスライド' "$tmp/ppt/slideLayouts/slideLayout1.xml" | head -n 1 | cut -c 1 || true)"
  if [[ -z "$variant" ]]; then
    echo "Skipped $pptx: its first slide layout is not the title slide of template A, B, C, or D." >&2
    continue
  fi
  echo "Template $variant ($pptx):"

  # Layout 4 (outline) shows only the wide logo, and layout 6 (content 2) only the stacked logo.
  wide="$(layout_media 4)"
  copy_media "$wide" logo-wide
  copy_media "$(layout_media 6)" logo-stacked

  # Layouts 1 to 3 (title, section 1, section 2) each show the wide logo and one full-page background.
  copy_media "$(layout_media 1 | grep -vxF "$wide")" "title-$variant"
  copy_media "$(layout_media 2 | grep -vxF "$wide")" "section-strong-$variant"
  copy_media "$(layout_media 3 | grep -vxF "$wide")" "section-pale-$variant"
done
