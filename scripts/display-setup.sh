#!/usr/bin/env bash
set -euo pipefail

xrandr --query | awk '
/ connected/ {
output=$1
preferred=""
max_rate=0

while (getline) {
    if ($0 !~ /^[ ]+[0-9]+x[0-9]+/)
        break

    res=$1

    if ($0 ~ /\+/) {
        preferred=res
        max_rate=0

        for (i=2; i<=NF; i++) {
            rate=$i
            gsub(/[*+]/, "", rate)
            if (rate+0 > max_rate)
                max_rate=rate
        }

        break
    }
}

if (preferred != "" && max_rate > 0)
    printf "%s %s %s\n", output, preferred, max_rate

}
' | while read -r out res rate; do
    xrandr --output "$out" --mode "$res" --rate "$rate"
done
