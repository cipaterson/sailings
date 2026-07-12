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

# Resolve a mermaid pandoc filter so ```mermaid blocks render as images in the
# .docx. GitHub renders mermaid natively in the Markdown source, but pandoc does
# not, so without this filter the diagrams would appear as raw code listings.
if command -v mermaid-filter >/dev/null 2>&1; then
  MERMAID_FILTER="mermaid-filter"
elif command -v npx >/dev/null 2>&1; then
  # Wrap npx so pandoc can invoke the on-demand mermaid-filter as an executable.
  MERMAID_FILTER="$TMP/mermaid-filter"
  cat > "$MERMAID_FILTER" <<'EOF'
#!/usr/bin/env bash
exec npx --yes mermaid-filter "$@"
EOF
  chmod +x "$MERMAID_FILTER"
else
  echo "Error: mermaid-filter not found and npx is unavailable." >&2
  echo "Install it with:  npm install -g mermaid-filter" >&2
  exit 1
fi

# PNG embeds reliably across Word and LibreOffice (broader than inline SVG).
export MERMAID_FILTER_FORMAT="${MERMAID_FILTER_FORMAT:-png}"

# mermaid-filter renders via headless Chrome (puppeteer). Point it at an existing
# Chromium and disable the sandbox so it launches reliably; mermaid-filter reads
# .puppeteer.json from its working directory ($TMP, where pandoc runs below).
# Auto-discover the browser so we don't pin a specific Chromium version.
CHROME_BIN="$(find "$HOME/.cache/puppeteer" -type f -path '*Chromium.app/Contents/MacOS/Chromium' 2>/dev/null | sort | tail -1)"
if [ -z "$CHROME_BIN" ] && [ -x "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" ]; then
  CHROME_BIN="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
fi
if [ -n "$CHROME_BIN" ]; then
  printf '{"executablePath": "%s", "args": ["--no-sandbox"]}\n' "$CHROME_BIN" > "$TMP/.puppeteer.json"
else
  printf '{"args": ["--no-sandbox"]}\n' > "$TMP/.puppeteer.json"
fi

# Run from $TMP so mermaid-filter's .puppeteer.json is picked up and its stray
# mermaid-filter.err log doesn't land in the repo; all paths passed to pandoc
# are absolute.
( cd "$TMP" && pandoc "$COMBINED" \
  --from=markdown+gfm_auto_identifiers \
  --to=docx \
  --filter="$MERMAID_FILTER" \
  --resource-path="$MANUAL_DIR" \
  --toc --toc-depth=2 \
  --output="$OUT" )

echo "Wrote $OUT"
