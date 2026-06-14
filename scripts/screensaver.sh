#!/bin/bash
# OLED-safe screensaver with floating colorful particles and waves
# Press Ctrl+C to exit

trap 'tput cnorm; tput sgr0; clear; exit' INT TERM

# Hide cursor and clear screen
tput civis
clear

# Get terminal size
get_size() {
    COLS=$(tput cols)
    ROWS=$(tput lines)
}
get_size
trap 'get_size' WINCH

# Colors (avoiding pure white to protect OLED)
colors=(
    '\033[38;5;201m'  # magenta
    '\033[38;5;51m'   # cyan
    '\033[38;5;46m'   # green
    '\033[38;5;226m'  # yellow
    '\033[38;5;208m'  # orange
    '\033[38;5;63m'   # purple
    '\033[38;5;33m'   # blue
    '\033[38;5;196m'  # red
    '\033[38;5;118m'  # lime
    '\033[38;5;213m'  # pink
)
reset='\033[0m'

# Particle characters
chars=('✦' '✧' '◆' '◇' '●' '○' '★' '☆' '◉' '◎' '❖' '✴' '✵' '❋' '✺' '⬡' '⬢')

# Initialize particles
declare -a px py pvx pvy pc pch
NUM_PARTICLES=35

for ((i=0; i<NUM_PARTICLES; i++)); do
    px[$i]=$((RANDOM % COLS))
    py[$i]=$((RANDOM % ROWS))
    pvx[$i]=$(( (RANDOM % 3) - 1 ))
    pvy[$i]=$(( (RANDOM % 3) - 1 ))
    [[ ${pvx[$i]} -eq 0 && ${pvy[$i]} -eq 0 ]] && pvx[$i]=1
    pc[$i]=${colors[$((RANDOM % ${#colors[@]}))]}
    pch[$i]=${chars[$((RANDOM % ${#chars[@]}))]}
done

# Wave parameters
wave_offset=0

frame=0
while true; do
    output=""

    # Clear with minimal flicker - build frame in memory
    declare -A screen

    # Draw sine wave pattern (moving)
    wave_color_idx=$(( (frame / 20) % ${#colors[@]} ))
    for ((x=0; x<COLS; x+=2)); do
        y=$(echo "scale=0; $ROWS/2 + (s(($x + $wave_offset) * 0.1) * $ROWS/4)" | bc -l 2>/dev/null)
        y=${y%.*}
        if [[ $y -ge 0 && $y -lt $ROWS ]]; then
            key="${y},${x}"
            screen[$key]="${colors[$wave_color_idx]}~${reset}"
        fi
        # Second wave
        y2=$(echo "scale=0; $ROWS/2 + (s(($x + $wave_offset + 30) * 0.08) * $ROWS/5)" | bc -l 2>/dev/null)
        y2=${y2%.*}
        if [[ $y2 -ge 0 && $y2 -lt $ROWS ]]; then
            key="${y2},${x}"
            c2_idx=$(( (wave_color_idx + 3) % ${#colors[@]} ))
            screen[$key]="${colors[$c2_idx]}≈${reset}"
        fi
    done

    # Update and draw particles
    for ((i=0; i<NUM_PARTICLES; i++)); do
        # Update position
        px[$i]=$(( ${px[$i]} + ${pvx[$i]} ))
        py[$i]=$(( ${py[$i]} + ${pvy[$i]} ))

        # Bounce off walls
        if [[ ${px[$i]} -le 0 || ${px[$i]} -ge $((COLS-1)) ]]; then
            pvx[$i]=$(( -${pvx[$i]} ))
            px[$i]=$(( ${px[$i]} + ${pvx[$i]} * 2 ))
            # Change color on bounce
            pc[$i]=${colors[$((RANDOM % ${#colors[@]}))]}
        fi
        if [[ ${py[$i]} -le 0 || ${py[$i]} -ge $((ROWS-1)) ]]; then
            pvy[$i]=$(( -${pvy[$i]} ))
            py[$i]=$(( ${py[$i]} + ${pvy[$i]} * 2 ))
            pc[$i]=${colors[$((RANDOM % ${#colors[@]}))]}
        fi

        # Clamp positions
        [[ ${px[$i]} -lt 0 ]] && px[$i]=0
        [[ ${px[$i]} -ge $COLS ]] && px[$i]=$((COLS-1))
        [[ ${py[$i]} -lt 0 ]] && py[$i]=0
        [[ ${py[$i]} -ge $ROWS ]] && py[$i]=$((ROWS-1))

        key="${py[$i]},${px[$i]}"
        screen[$key]="${pc[$i]}${pch[$i]}${reset}"
    done

    # Render frame
    printf '\033[H'  # Move cursor home

    for ((y=0; y<ROWS; y++)); do
        line=""
        for ((x=0; x<COLS; x++)); do
            key="${y},${x}"
            if [[ -n "${screen[$key]}" ]]; then
                line+="${screen[$key]}"
            else
                line+=" "
            fi
        done
        printf '%s\n' "$line"
    done

    wave_offset=$((wave_offset + 2))
    frame=$((frame + 1))

    sleep 0.08
done
