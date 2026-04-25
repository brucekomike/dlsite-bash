#!/bin/bash
source load.sh
for i in $(tac purchase_list.csv); do
    echo "$i"
done | while IFS=, read -r id time; do
    purchase_date=$(date -d "$time" -I 2>/dev/null || echo "$time")
    echo "Fetching info for $id: purchased at $purchase_date"
    dlsite-get-work-info "$id" | while IFS=\| read -r id name maker file_count; do
        echo "ID: $id"
        echo "Name: $name"
        echo "Maker: $maker"
        echo "Remote file count: $file_count"
        echo "-----------------------------"
        db_write_info "$id" "$name" "$maker" "$file_count" "$purchase_date" "info.db" 
    done
done