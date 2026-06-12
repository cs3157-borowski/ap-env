#!/usr/bin/env bash

IMAGE="$1"

# Print the green status message
echo -e "\033[1;32m[*] Synchronizing with remote registry and fetching latest course image updates...\033[0m"

# Get terminal columns, default to 80 if not set
COLS=$(tput cols 2>/dev/null || echo 80)
GLOBAL_BAR_WIDTH=$((COLS - 35))
if [ "$GLOBAL_BAR_WIDTH" -lt 15 ]; then GLOBAL_BAR_WIDTH=15; fi
if [ "$GLOBAL_BAR_WIDTH" -gt 50 ]; then GLOBAL_BAR_WIDTH=50; fi

AWK_SCRIPT='
BEGIN {
    RS="\r|\n"
    total_layers = 0
    current_stage = "Comparing"
    srand(); last_time = srand()
    last_total_dl = 0
    avg_speed = 0
    
    chars[0] = ""; chars[1] = "▏"; chars[2] = "▎"; chars[3] = "▍";
    chars[4] = "▌"; chars[5] = "▋"; chars[6] = "▊"; chars[7] = "▉";
    
    lines_drawn = 0
}
function percent_bar(pct, width,    p_int, full_blocks, rem, bar, i, blank_len) {
    if (width < 5) width = 5
    p_int = int((pct / 100) * width * 8)
    full_blocks = int(p_int / 8)
    rem = p_int % 8
    
    bar = ""
    for (i = 0; i < full_blocks; i++) bar = bar "█"
    bar = bar chars[rem]
    
    blank_len = width - full_blocks
    if (rem > 0) blank_len--
    
    for (i = 0; i < blank_len; i++) bar = bar "░"
    return bar
}
function to_bytes(str,    val) {
    gsub(/^[ \t]+|[ \t]+$/, "", str)
    val = str + 0
    if (str ~ /GB/) return val * 1024 * 1024 * 1024
    if (str ~ /MB/) return val * 1024 * 1024
    if (str ~ /kB/) return val * 1024
    if (str ~ /B/) return val
    return val
}
function format_size(bps) {
    if (bps <= 0) return "0 B"
    if (bps >= 1024 * 1024 * 1024) return sprintf("%.2f GB", bps / (1024*1024*1024))
    if (bps >= 1024 * 1024) return sprintf("%.1f MB", bps / (1024*1024))
    if (bps >= 1024) return sprintf("%.1f kB", bps / 1024)
    return sprintf("%d B", bps)
}
function format_speed(bps) {
    if (bps <= 0) return ""
    if (bps >= 1024 * 1024 * 1024) return sprintf("%.2f GB/s", bps / (1024*1024*1024))
    if (bps >= 1024 * 1024) return sprintf("%.2f MB/s", bps / (1024*1024))
    if (bps >= 1024) return sprintf("%.1f kB/s", bps / 1024)
    return sprintf("%d B/s", bps)
}

function draw_ui(    dl_count, ex_count, dl_complete, ex_complete, i, l, now, bytes_diff, time_diff, speed_bps, total_points, global_pct, size_str, spd, stats, prefix, max_display, display_count, idx, display_arr, l_pct, l_state, show_bytes, layer_bar_width, l_bytes_str, short_l, state_col) {
    # 1. Update Global Status
    dl_count = 0; ex_count = 0; dl_complete = 0; ex_complete = 0;
    for (i = 0; i < total_layers; i++) {
        l = layer_list[i]
        if (states[l] == "Downloading" || states[l] == "Pulling") dl_count++
        else if (states[l] == "Extracting") ex_count++
        
        if (states[l] == "Extracting" || states[l] == "Complete") dl_complete++
        if (states[l] == "Complete") ex_complete++
    }
    
    if (total_layers > 0 && current_stage != "Complete") {
        if (dl_count > 0) current_stage = "Downloading"
        else if (ex_count > 0) current_stage = "Extracting"
        else current_stage = "Verifying"
    }

    srand(); now = srand()
    if (now > last_time) {
        total_dl = 0; grand_total = 0;
        for (i = 0; i < total_layers; i++) {
            l = layer_list[i]
            total_dl += downloaded_bytes[l] 
            grand_total += total_bytes[l]
        }
        
        bytes_diff = total_dl - last_total_dl
        time_diff = now - last_time
        speed_bps = bytes_diff / time_diff
        
        if (avg_speed == 0) avg_speed = speed_bps
        else avg_speed = (avg_speed * 0.6) + (speed_bps * 0.4)
        
        last_time = now
        last_total_dl = total_dl
    }
    
    if (total_layers > 0) {
        total_points = 0
        for (i = 0; i < total_layers; i++) total_points += points[layer_list[i]]
        global_pct = (total_points / (total_layers * 100)) * 100
        if (global_pct > 100) global_pct = 100
    } else {
        global_pct = 0.00
    }
    
    # 2. Setup Screen Space
    if (lines_drawn > 0) {
        printf "\r\033[%dA\033[J", lines_drawn
    } else {
        printf "\r\033[J"
    }
    lines_drawn = 0
    
    # 3. Draw Global Bar
    printf "\033[K\033[1;36m%-12s\033[0m %s%6.2f%%\r\n", current_stage, percent_bar(global_pct, global_width), global_pct
    lines_drawn++
    
    # 4. Draw Global Stats
    if (current_stage == "Downloading" || current_stage == "Extracting") {
        if (grand_total > 0) size_str = format_size(total_dl) " / " format_size(grand_total)
        else size_str = "Calculating..."
        
        if (current_stage == "Downloading") {
            spd = (avg_speed > 0) ? format_speed(avg_speed) : "0 B/s"
            if (cols >= 80) stats = sprintf("Speed: %s  |  Data: %s  |  Layers: %d/%d DL", spd, size_str, dl_complete, total_layers)
            else if (cols >= 60) stats = sprintf("Speed: %s  |  Data: %s", spd, size_str)
            else stats = sprintf("Data: %s", size_str)
        } else {
            if (cols >= 80) stats = sprintf("Data: %s  |  Layers: %d/%d Extracted", size_str, ex_complete, total_layers)
            else stats = sprintf("Data: %s", size_str)
        }
        
        prefix = (total_layers > 0) ? "  ├─" : "  └─"
        printf "\033[K%s \033[1;30m%s\033[0m\r\n", prefix, stats
        lines_drawn++
    }
    
    # 5. Determine which layers to display (cap at 5 to prevent terminal ceiling scroll spam)
    max_display = 5
    display_count = 0
    for (idx in drawn_set) delete drawn_set[idx]
    
    # Priority 1: Actively downloading or extracting
    for (i = 0; i < total_layers && display_count < max_display; i++) {
        l = layer_list[i]
        if (states[l] == "Downloading" || states[l] == "Extracting") {
            display_arr[display_count++] = l; drawn_set[l] = 1
        }
    }
    # Priority 2: Pulling or waiting
    for (i = 0; i < total_layers && display_count < max_display; i++) {
        l = layer_list[i]
        if (!(l in drawn_set) && (states[l] == "Pulling" || states[l] == "Waiting")) {
            display_arr[display_count++] = l; drawn_set[l] = 1
        }
    }
    # Priority 3: Complete
    for (i = 0; i < total_layers && display_count < max_display; i++) {
        l = layer_list[i]
        if (!(l in drawn_set)) {
            display_arr[display_count++] = l; drawn_set[l] = 1
        }
    }
    
    # 6. Draw Layers
    for (i = 0; i < display_count; i++) {
        l = display_arr[i]
        l_pct = points[l]
        l_state = states[l]
        
        # Responsive Layer Rendering
        show_bytes = (cols >= 75)
        layer_bar_width = (cols >= 55) ? 15 : 5
        
        l_bytes_str = ""
        if (show_bytes && l in downloaded_bytes && l in total_bytes && total_bytes[l] > 0) {
            l_bytes_str = sprintf("%s / %s", format_size(downloaded_bytes[l]), format_size(total_bytes[l]))
        }
        
        short_l = substr(l, 1, 7)
        prefix = (i == display_count - 1) ? "  └─" : "  ├─"
        
        state_col = "\033[1;30m"
        if (l_state == "Downloading") state_col = "\033[1;34m"
        else if (l_state == "Extracting") state_col = "\033[1;33m"
        else if (l_state == "Complete") state_col = "\033[1;32m"
        else if (l_state == "Pulling") state_col = "\033[1;36m"
        
        if (show_bytes) {
            printf "\033[K%s [\033[1;37m%s\033[0m] %s%6.2f%% %s%-12s\033[0m %s\r\n", prefix, short_l, percent_bar(l_pct, layer_bar_width), l_pct, state_col, l_state, l_bytes_str
        } else {
            printf "\033[K%s [\033[1;37m%s\033[0m] %s%6.2f%% %s%-12s\033[0m\r\n", prefix, short_l, percent_bar(l_pct, layer_bar_width), l_pct, state_col, l_state
        }
        lines_drawn++
    }
    fflush()
}

/Pulling fs layer/ {
    layer = $1; sub(/:/, "", layer)
    if (!(layer in layers)) { 
        layers[layer] = 1; 
        layer_list[total_layers] = layer;
        points[layer] = 0; 
        states[layer] = "Waiting" 
        total_layers++; 
    }
}
/Already exists/ {
    layer = $1; sub(/:/, "", layer)
    if (!(layer in layers)) { 
        layers[layer] = 1; 
        layer_list[total_layers] = layer;
        total_layers++; 
    }
    points[layer] = 100
    states[layer] = "Complete"
}
/Downloading|Extracting/ {
    layer = $1; sub(/:/, "", layer)
    if (layer in layers) {
        split($0, arr, "[][]")
        bar = arr[2]
        info = arr[3]
        
        c = gsub(/[=>]/, "", bar)
        if ($2 == "Downloading") {
            states[layer] = "Downloading"
            if (c > points[layer] || points[layer] > 50) points[layer] = c
            
            if (split(info, bytes, "/") == 2) {
                downloaded_bytes[layer] = to_bytes(bytes[1])
                total_bytes[layer] = to_bytes(bytes[2])
            }
        } else if ($2 == "Extracting") {
            states[layer] = "Extracting"
            if (50 + c > points[layer]) points[layer] = 50 + c
            if (layer in total_bytes) downloaded_bytes[layer] = total_bytes[layer]
        }
    }
}
/Pull complete/ {
    layer = $1; sub(/:/, "", layer)
    points[layer] = 100
    states[layer] = "Complete"
    if (layer in total_bytes) downloaded_bytes[layer] = total_bytes[layer]
}
/Status: Image is up to date/ || /Status: Downloaded newer image/ {
    current_stage = "Complete"
    # Erase the UI from the screen completely upon completion
    if (lines_drawn > 0) {
        printf "\r\033[%dA\033[J", lines_drawn
    } else {
        printf "\r\033[J"
    }
    fflush()
}
{
    if (current_stage != "Complete") {
        draw_ui()
    }
}'

# Cleanup function to restore terminal state
cleanup_terminal() {
    printf "\033[?7h"
    stty sane 2>/dev/null || true
}
trap cleanup_terminal EXIT SIGINT SIGTERM

# Disable line wrapping natively to prevent terminal scrolling loops
printf "\033[?7l"

# Execute docker pull and parse it entirely within AWK
if [[ "$OSTYPE" == "darwin"* ]]; then
    script -q /dev/null docker pull "$IMAGE" | awk -v cols="$COLS" -v global_width="$GLOBAL_BAR_WIDTH" "$AWK_SCRIPT"
else
    script -q -c "docker pull $IMAGE" /dev/null | awk -v cols="$COLS" -v global_width="$GLOBAL_BAR_WIDTH" "$AWK_SCRIPT"
fi
