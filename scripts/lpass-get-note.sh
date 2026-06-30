#!/bin/sh
set -e

EMAIL="$1"
NOTE="$2"
OUT="/tmp/note.txt"

lpass login "$EMAIL"
lpass show --notes "$NOTE" > "$OUT"
