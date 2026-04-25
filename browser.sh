#!/bin/bash

# --- Configuration ---
# Path to your SQLite database file
DB_FILE="info.db"

source load.sh
# --- Pre-checks ---
# Check if the database file exists
if [ ! -f "$DB_FILE" ]; then
    dialog --msgbox "Error: Database file '$DB_FILE' not found.\nPlease check the path and try again." 10 50
    exit 1
fi


# --- Prepare Data for Dialog ---
# Format the SQLite output into a format suitable for dialog's --menu option.
# dialog menu format: "tag1" "item1" "tag2" "item2" ...
# We will use the record's 'id' as the tag for easy selection.
dialog_list=()
while IFS=$'\t' read -r id name circle file_count; do
    # Skip empty or incomplete lines
    if [ -n "$id" ]; then
        # Add one tag/item pair per row so dialog receives correctly quoted args.
        dialog_list+=("$id" "$circle - $name" )
    fi
done < <(sqlite3 -separator $'\t' "$DB_FILE" "SELECT id, name, circle, file_count FROM works ORDER BY id;")

# Check if any records were found
if [ ${#dialog_list[@]} -eq 0 ]; then
    dialog --msgbox "No records found in the table." 10 50
    exit 0
fi

# --- Display Records using Dialog ---
# Use dialog --menu to present the list of works to the user.
# --menu <height> <width> <menu_height> <text_width> <menu_items>
selected_id=$(dialog --clear \
                --backtitle "SQLite Work Viewer" \
                --title "Select Work for Download" \
                --menu "Please select a work to download:" 15 60 10 \
                "${dialog_list[@]}" \
                2>&1 >/dev/tty) # Redirect stderr to tty for dialog to work correctly and capture selection.

# --- Handle User Interaction ---
# Check if the user cancelled the selection
if [ $? -ne 0 ]; then
    dialog --msgbox "Operation cancelled." 10 30
    exit 0
fi

# --- Retrieve Full Record Information ---
# Fetch the complete record details based on the selected ID.
# Assumes 'id' is unique.
selected_record=$(sqlite3 "$DB_FILE" "SELECT id, name, circle, file_count FROM works WHERE id = '$selected_id';")

# Check if the record was successfully retrieved
if [ -z "$selected_record" ]; then
    dialog --msgbox "Error: Could not find the selected record (ID: $selected_id)." 10 50
    exit 1
fi

# Parse the selected record's details
IFS='|' read -r id name circle file_count <<< "$selected_record"

# --- Confirm Download ---
# Ask the user for confirmation before proceeding with the download.
dialog --yesno "Are you sure you want to download work '$name' (ID: $id)?\nThis will execute the script: $DOWNLOAD_SCRIPT" 10 60

# --- Execute Download Script ---
# Check user's confirmation
if [ $? -eq 0 ]; then
    # Execute the download script, passing the selected record's details as arguments.
    # You will need to modify download_script.sh to accept and process these arguments.
    dialog --infobox "Executing download script..." 5 40
    mkdir -p "downloads/$circle/$name"
    dlsite-download-single "$id" "downloads/$circle/$name/$id.zip"
    
    # Check the exit status of the download script
    if [ $? -eq 0 ]; then
        dialog --msgbox "Download script executed successfully." 10 50
    else
        dialog --msgbox "Download script execution failed." 10 50
    fi
else
    dialog --msgbox "Download cancelled." 10 30
fi

