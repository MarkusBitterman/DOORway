#!/usr/bin/env bash
# gen-litclock.sh — bake the literature-clock quote dataset into the JSON the
# DOORway right-sidebar LiteratureClock service reads.
#
# Source: the annotated literary-clock dataset (pipe-delimited
#   time|timestring|quote|title|author|rating) from the original project
#   github.com/JohsEnevoldsen/literature-clock, lineage of Jaap Meijers'
#   e-reader clock. Quotes are short literary excerpts shown with title/author
#   attribution.
#
# Filtering: drops rows rated nsfw/nswf (keeps sfw + unrated "unknown"), which
# covers ~1409 of 1440 minutes. Output is keyed by "HH:MM" for O(1) minute
# lookup; <br/> is normalised to newlines.
#
# Run once at authoring time; the JSON output is committed (the deployed path is
# a read-only Nix store symlink, so nothing regenerates it at runtime).
#
# Usage:
#   gen-litclock.sh [SOURCE_CSV]
#     SOURCE_CSV  optional local path; if omitted, fetched over the network.
set -euo pipefail

SRC_URL="https://raw.githubusercontent.com/JohsEnevoldsen/literature-clock/master/litclock_annotated.csv"
OUT_DIR="${DOORWAY_DATA_HOME:-$HOME/.local/share/doorway}/litclock"
# When run from the repo, prefer writing into the source tree. Walk up from the
# script looking for the repo root (flake.nix) so the committed JSON is updated
# in place rather than into the read-only deployed Nix store path.
d="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
while [[ "$d" != "/" ]]; do
    if [[ -f "$d/flake.nix" && -d "$d/Configs/.local/share/doorway" ]]; then
        OUT_DIR="$d/Configs/.local/share/doorway/litclock"
        break
    fi
    d="$(dirname "$d")"
done

src="${1:-}"
tmp=""
if [[ -z "$src" ]]; then
    tmp="$(mktemp)"; trap 'rm -f "$tmp"' EXIT
    echo "fetching $SRC_URL" >&2
    curl -fsSL --max-time 60 "$SRC_URL" -o "$tmp"
    src="$tmp"
fi

mkdir -p "$OUT_DIR"
out="$OUT_DIR/quotes.json"

python3 - "$src" "$out" <<'PY'
import sys, json, collections

src, out = sys.argv[1], sys.argv[2]
by_min = collections.OrderedDict()
kept = dropped = 0
with open(src, encoding="utf-8") as f:
    for line in f:
        line = line.rstrip("\n")
        if not line:
            continue
        parts = line.split("|")
        if len(parts) != 6:
            continue
        time, timestr, quote, title, author, rating = parts
        if rating.strip().lower() in ("nsfw", "nswf"):
            dropped += 1
            continue
        quote = quote.replace("<br/>", "\n").replace("<br>", "\n").strip()
        by_min.setdefault(time, []).append({
            "q": quote, "t": timestr, "a": author, "b": title,
        })
        kept += 1

# stable minute order
by_min = collections.OrderedDict(sorted(by_min.items()))
with open(out, "w", encoding="utf-8") as f:
    json.dump(by_min, f, ensure_ascii=False, separators=(",", ":"))

print(f"kept {kept} quotes across {len(by_min)} minutes "
      f"(dropped {dropped} explicit) -> {out}", file=sys.stderr)
PY

# Attribution alongside the data.
cat >"$OUT_DIR/ATTRIBUTION.md" <<'EOF'
# Literature Clock quote data

Quotes are short literary excerpts from the annotated literary-clock dataset
(https://github.com/JohsEnevoldsen/literature-clock), lineage of Jaap Meijers'
e-reader clock. Each entry is shown with its book title and author. Rows rated
nsfw/nswf are excluded by gen-litclock.sh.
EOF

echo "wrote $out and $OUT_DIR/ATTRIBUTION.md" >&2
