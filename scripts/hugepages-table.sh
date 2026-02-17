#!/usr/bin/env bash
set -euo pipefail

BASE="/sys/kernel/mm/hugepages"

if [[ ! -d "$BASE" ]]; then
    echo "HugePages sysfs not found. Is this a Linux system with hugetlb enabled?"
    exit 1
fi

printf "\n%-10s %-10s %-10s %-10s %-10s\n" "SIZE" "TOTAL" "FREE" "RESV" "USED"
printf "%-10s %-10s %-10s %-10s %-10s\n" "--------" "--------" "--------" "--------" "--------"

for d in "$BASE"/hugepages-*; do
    size_kb=$(basename "$d" | sed -E 's/hugepages-([0-9]+)kB/\1/')
    
    # Convert to readable format
    if (( size_kb >= 1048576 )); then
        size_human="$((size_kb / 1024 / 1024))G"
    elif (( size_kb >= 1024 )); then
        size_human="$((size_kb / 1024))M"
    else
        size_human="${size_kb}K"
    fi

    total=$(<"$d/nr_hugepages")
    free=$(<"$d/free_hugepages")
    resv=$(<"$d/resv_hugepages")

    used=$((total - free))

    printf "%-10s %-10s %-10s %-10s %-10s\n" \
        "$size_human" "$total" "$free" "$resv" "$used"
done

echo
