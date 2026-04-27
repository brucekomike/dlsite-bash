#!/bin/bash
source load.sh

if [[ $(uname) == "Darwin" ]]; then
    function date_cmd() {
        date -jf "%Y-%m-%dT%H:%M:%S.000000Z" -I "$1"
    }
    export -f date_cmd
else
    function date_cmd() {
        date -d "$1" -I
    }
    export -f date_cmd
fi
for i in $(awk '{a[i++]=$0} END {for (j=i-1; j>=0;) print a[j--] }' purchase_list.csv); do
    echo "$i"
done | while IFS=, read -r id time; do

    purchase_date=$(date_cmd "$time" || echo "$time")
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