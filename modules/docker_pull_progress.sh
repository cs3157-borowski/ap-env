#!/usr/bin/env bash

IMAGE="$1"

# create progress bar for given percentage, fully compatible with macOS bash 3.2
percentBar () {
    local prct totlen=$((8*$2)) lastchar barstring blankstring
    printf -v prct %.2f "$1"
    local p_int=$(( 10#${prct/.} * totlen / 10000 ))
    local p_rem=$(( p_int % 8 ))
    
    local chars=("" "▏" "▎" "▍" "▌" "▋" "▊" "▉")
    lastchar="${chars[$p_rem]}"
    
    printf -v barstring '%*s' $((p_int / 8)) ''
    barstring="${barstring// /█}$lastchar"
    
    local blank_len=$(( (totlen - p_int) / 8 ))
    if [ $blank_len -gt 0 ]; then
        printf -v blankstring '%*s' $blank_len ''
        blankstring="${blankstring// /░}"
    else
        blankstring=""
    fi
    printf -v "$3" '%s%s' "$barstring" "$blankstring"
}

export -f percentBar

AWK_SCRIPT='
BEGIN {
    RS="\r|\n"
    total_layers = 0
}
/Pulling fs layer/ {
    layer = $1; sub(/:/, "", layer)
    if (!(layer in layers)) { layers[layer] = 1; total_layers++; points[layer] = 0 }
}
/Already exists/ {
    layer = $1; sub(/:/, "", layer)
    if (!(layer in layers)) { layers[layer] = 1; total_layers++; }
    points[layer] = 100
}
/Downloading|Extracting/ {
    layer = $1; sub(/:/, "", layer)
    if (layer in layers) {
        split($0, arr, "[][]")
        bar = arr[2]
        c = gsub(/[=>]/, "", bar)
        if ($2 == "Downloading") {
            if (c > points[layer] || points[layer] > 50) points[layer] = c
        } else if ($2 == "Extracting") {
            if (50 + c > points[layer]) points[layer] = 50 + c
        }
    }
}
/Pull complete/ {
    layer = $1; sub(/:/, "", layer)
    points[layer] = 100
}
/Status: Image is up to date/ || /Status: Downloaded newer image/ {
    printf "100.00\n"
}
{
    if (total_layers > 0) {
        total_points = 0
        for (l in points) { total_points += points[l] }
        pct = (total_points / (total_layers * 100)) * 100
        if (pct > 100) pct = 100
        printf "%.2f\n", pct
    }
}'

# Print the green status message
echo -e "\033[1;32m[*] Synchronizing with remote registry and fetching latest course image updates...\033[0m"

# Get terminal columns, default to 80 if not set
COLS=$(tput cols 2>/dev/null || echo 80)
BAR_WIDTH=$((COLS - 7))

# Helper to read stream and draw bar
draw_bar() {
    local last_pct="0.00"
    while read -r pct; do
        percentBar "$pct" "$BAR_WIDTH" bar
        # No hardcoded colors; use terminal defaults
        printf '\r%s%6.2f%%' "$bar" "$pct"
        last_pct="$pct"
    done
    
    if [ "$last_pct" == "0.00" ]; then
        percentBar "100.00" "$BAR_WIDTH" bar
        # Explicit \r\n returns cursor to far left edge AND down
        printf '\r%s%6.2f%%\r\n' "$bar" "100.00"
    else
        printf '\r\n'
    fi
}

# Use script command to force pseudo-TTY so docker outputs progress
if [[ "$OSTYPE" == "darwin"* ]]; then
    script -q /dev/null docker pull "$IMAGE" | awk "$AWK_SCRIPT" | draw_bar
else
    script -q -c "docker pull $IMAGE" /dev/null | awk "$AWK_SCRIPT" | draw_bar
fi

# Ensure terminal sanity in case script command corrupted it (prevents staircasing text)
stty sane 2>/dev/null || true
