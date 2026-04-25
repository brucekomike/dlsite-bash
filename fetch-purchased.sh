#!/bin/bash
source load.sh

dlsite-lib-info
if [ -f purchase_list.csv ]; then
    echo "purchase_list.csv already exists. Do you want to update it? (Y/n)"
    read -r answer
    #Yes, y, or empty input will update the purchase_list.csv
    if [[ "$answer" == "Y" || "$answer" == "y" || -z "$answer" ]]; then
        echo "Updating purchase_list.csv..."
        dlsite-update-lib
        echo "purchase_list.csv updated."
    else
        echo "purchase_list.csv not updated."
    fi
else
    echo "purchase_list.csv does not exist. Creating purchase_list.csv..."
    dlsite-update-lib
    echo "purchase_list.csv created."
fi

