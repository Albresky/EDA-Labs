#!/bin/bash
###
 # Copyright (c) 2025 by Albresky, All Rights Reserved. 
 # 
 # @Author: Albresky albre02@outlook.com
 # @Date: 2025-06-03 23:01:25
 # @LastEditTime: 2025-06-10 00:07:20
 # @FilePath: /BUPT-EDA-Labs/lab2/syn/scripts/gen_tcl.sh
 # 
 # @Description: 
### 
set -eo pipefail

if [ $# -ne 3 ]; then
    echo "Args invalid"
    echo "Usage: $0 <frequency> <input_tcl> <output_tcl>"
    exit 1
fi

freq=$1
template=$2
out=$3

if [ ! -f "$template" ]; then
    echo "Error: Template file $template not found!"
    exit 1
fi

calculate_period() {
    local freq_input="$1"
    
    if [[ $freq_input =~ ^([0-9]+\.?[0-9]*)([A-Za-z]+)$ ]]; then
        local number="${BASH_REMATCH[1]}"
        local unit="${BASH_REMATCH[2]}"
        
        case "${unit^^}" in
            "GHZ"|"G")
                multiplier=1000000000
                ;;
            "MHZ"|"M")
                multiplier=1000000
                ;;
            "KHZ"|"K")
                multiplier=1000
                ;;
            "HZ"|"")
                multiplier=1
                ;;
            *)
                echo "Error: Unsupported frequency unit: $unit"
                exit 1
                ;;
        esac
        
        period=$(echo "scale=3; 1000000000 / ($number * $multiplier)" | bc)
        
        period=$(echo "$period" | sed 's/\.000$//' | sed 's/\.\([0-9]*[1-9]\)0*$/.\1/')
        
        echo "$period"
    else
        echo "Error: Invalid frequency format: $freq_input"
        echo "Expected format: <number><unit> (e.g., 10MHz, 100KHz)"
        exit 1
    fi
}

period=$(calculate_period "$freq")

mkdir -p "$(dirname "$out")"

sed \
    -e "s/create_clock -period [0-9.]*/create_clock -period $period/" \
    -e "s|default|${freq}|g" \
    -e "s|\./rpt|./rpt|g" \
    -e "s|\./mapped|./mapped|g" \
    -e "s|\./unmapped|./unmapped|g" \
    -e "s/slib_name/typical_1v2c25/g" \
    "$template" > "$out"

echo "[INFO] Generated $out"