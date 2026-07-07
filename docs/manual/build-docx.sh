#!/usr/bin/env bash
#
# Build docs/Lady-Nelson-Sailings-Manual.docx from the Markdown chapters in
# this directory.
#
# Link handling:
#   * Links to project files (../../PATH) are rewritten to point at the
#     corresponding file on GitHub:
#       https://github.com/cipaterson/sailings/blob/main/PATH
#   * Cross-chapter links (NN-name.md or NN-name.md#anchor) are turned into
#     internal document links so navigation stays inside the .docx.
#   * Same-page anchors (#anchor) and image links are left untouched.
#
# Requires: pandoc (brew install pandoc).

set -euo pipefail

MANUAL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="$MANUAL_DIR/../Lady-Nelson-Sailings-Manual.docx"
REPO_BLOB="https://github.com/cipaterson/sailings/blob/main"

# Chapters in reading order.
CHAPTERS=(
  00-introduction.md
  10-developing.md
  20-external-setup.md
  30-deploying.md
  40-backup-restore.md
  50-monitoring.md
  60-troubleshooting.md
)

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
COMBINED="$TMP/manual.md"
: > "$COMBINED"

for ch in "${CHAPTERS[@]}"; do
  # Give each chapter's first heading a stable id (#chap-NN) so bare
  # cross-chapter links can target it, then rewrite links.
  id="chap-${ch%%-*}"
  ruby -e '
    id, blob = ARGV[0], ARGV[1]
    text = STDIN.read
    first = true
    text = text.lines.map do |line|
      if first && line =~ /^#/
        first = false
        line.chomp + " {##{id}}\n"
      else
        line
      end
    end.join
    # Project-file links: ](../../PATH) -> GitHub blob URL.
    text = text.gsub(/\]\(\.\.\/\.\.\/([^)]+)\)/) { "](#{blob}/#{$1})" }
    # Cross-chapter links with an anchor: ](NN-name.md#anchor) -> ](#anchor).
    text = text.gsub(/\]\(\d\d-[^)#]+\.md(#[^)]+)\)/) { "](#{$1})" }
    # Bare cross-chapter links: ](NN-name.md) -> ](#chap-NN).
    text = text.gsub(/\]\((\d\d)-[^)#]+\.md\)/) { "](#chap-#{$1})" }
    # Manual index (docs/manual/README.md) -> GitHub blob URL.
    text = text.gsub(/\]\(README\.md\)/) { "](#{blob}/docs/manual/README.md)" }
    print text
  ' "$id" "$REPO_BLOB" < "$MANUAL_DIR/$ch" >> "$COMBINED"
  printf '\n\n' >> "$COMBINED"
done

pandoc "$COMBINED" \
  --from=markdown+gfm_auto_identifiers \
  --to=docx \
  --resource-path="$MANUAL_DIR" \
  --toc --toc-depth=2 \
  --output="$OUT"

echo "Wrote $OUT"
