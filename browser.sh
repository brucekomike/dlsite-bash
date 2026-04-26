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

download_work() {
    local id="$1"
    local name="$2"
    local circle="$3"
    local count="$4"
    local confirm="${5:-true}"

    if [ "$confirm" = "true" ]; then
        dialog --yesno "Download '$name' (ID: $id)?" 10 60
        if [ $? -ne 0 ]; then
            dialog --msgbox "Download cancelled." 10 30
            return 0
        fi
    fi

    dialog --infobox "Downloading '$name' ($id)..." 5 50
    mkdir -p "downloads/$circle/$name"
    dlsite-download-multi "$id" "$count" "downloads/$circle/$name"
    local rc=$?

    if [ "$confirm" = "true" ]; then
        if [ $rc -eq 0 ]; then
            dialog --msgbox "Download completed: $name" 10 50
        else
            dialog --msgbox "Download failed: $name" 10 50
        fi
    fi

    return $rc
}

# --- Main loop ---
while true; do
    action=$(dialog --clear \
                --backtitle "DLsite Work Downloader" \
                --title "Main Menu" \
                --menu "Select an action:" 15 60 4 \
                "by_id"     "Browse and download a work" \
                "by_circle" "Download works by circle" \
                "by_recent" "Download works by recent purchase" \
                "all"       "Download all works" \
                2>&1 >/dev/tty)

    [ $? -ne 0 ] && break

    case "$action" in

        # --- Browse all works, pick one ---
        by_id)
            dialog_list=()
            while IFS=$'\t' read -r id name circle file_count; do
                [ -n "$id" ] && dialog_list+=("$id" "$circle - $name")
            done < <(sqlite3 -separator $'\t' "$DB_FILE" \
                "SELECT id, name, circle, file_count FROM works ORDER BY id;")

            if [ ${#dialog_list[@]} -eq 0 ]; then
                dialog --msgbox "No records found in the database." 10 50
                continue
            fi

            selected_id=$(dialog --clear \
                --backtitle "DLsite Work Downloader" \
                --title "Select Work for Download" \
                --menu "Please select a work to download:" 20 70 15 \
                "${dialog_list[@]}" \
                2>&1 >/dev/tty)

            [ $? -ne 0 ] && continue

            escaped_id="${selected_id//\'/\'\'}"
            IFS='|' read -r id name circle file_count <<< \
                "$(sqlite3 "$DB_FILE" "SELECT id, name, circle, file_count FROM works WHERE id = '$escaped_id';")"
            download_work "$id" "$name" "$circle" "$file_count"
            ;;

        # --- Pick a circle, then download one or all works in it ---
        by_circle)
            circle_list=()
            while IFS=$'\t' read -r circle cnt; do
                [ -n "$circle" ] && circle_list+=("$circle" "($cnt works)")
            done < <(sqlite3 -separator $'\t' "$DB_FILE" \
                "SELECT circle, COUNT(*) FROM works GROUP BY circle ORDER BY circle;")

            if [ ${#circle_list[@]} -eq 0 ]; then
                dialog --msgbox "No circles found in the database." 10 50
                continue
            fi

            selected_circle=$(dialog --clear \
                --backtitle "DLsite Work Downloader" \
                --title "Select Circle" \
                --menu "Select a circle:" 20 70 15 \
                "${circle_list[@]}" \
                2>&1 >/dev/tty)

            [ $? -ne 0 ] && continue

            # Escape single quotes for safe SQL use
            escaped_circle="${selected_circle//\'/\'\'}"

            work_list=()
            while IFS=$'\t' read -r id name; do
                [ -n "$id" ] && work_list+=("$id" "$name")
            done < <(sqlite3 -separator $'\t' "$DB_FILE" \
                "SELECT id, name FROM works WHERE circle = '$escaped_circle' ORDER BY id;")

            if [ ${#work_list[@]} -eq 0 ]; then
                dialog --msgbox "No works found for circle '$selected_circle'." 10 50
                continue
            fi

            download_choice=$(dialog --clear \
                --backtitle "DLsite Work Downloader" \
                --title "Circle: $selected_circle" \
                --menu "Download options:" 12 60 2 \
                "select" "Select a specific work" \
                "all"    "Download all works in this circle" \
                2>&1 >/dev/tty)

            [ $? -ne 0 ] && continue

            if [ "$download_choice" = "all" ]; then
                dialog --yesno "Download all works in '$selected_circle'?" 10 60
                if [ $? -eq 0 ]; then
                    failed=0
                    while IFS=$'\t' read -r id name circle file_count; do
                        download_work "$id" "$name" "$circle" "$file_count" "false" || ((failed++))
                    done < <(sqlite3 -separator $'\t' "$DB_FILE" \
                        "SELECT id, name, circle, file_count FROM works WHERE circle = '$escaped_circle' ORDER BY id;")
                    if [ "$failed" -eq 0 ]; then
                        dialog --msgbox "All downloads for '$selected_circle' completed." 10 50
                    else
                        dialog --msgbox "$failed download(s) failed for '$selected_circle'." 10 50
                    fi
                fi
            else
                selected_id=$(dialog --clear \
                    --backtitle "DLsite Work Downloader" \
                    --title "Circle: $selected_circle" \
                    --menu "Select a work to download:" 20 70 15 \
                    "${work_list[@]}" \
                    2>&1 >/dev/tty)

                [ $? -ne 0 ] && continue

                escaped_id="${selected_id//\'/\'\'}"
                IFS='|' read -r id name circle file_count <<< \
                    "$(sqlite3 "$DB_FILE" "SELECT id, name, circle, file_count FROM works WHERE id = '$escaped_id';")"
                download_work "$id" "$name" "$circle" "$file_count"
            fi
            ;;

        # --- Browse works ordered by most recent purchase date ---
        by_recent)
            dialog_list=()
            while IFS=$'\t' read -r id name circle purchase_date; do
                [ -n "$id" ] && dialog_list+=("$id" "${purchase_date:-N/A} | $circle - $name")
            done < <(sqlite3 -separator $'\t' "$DB_FILE" \
                "SELECT id, name, circle, purchase_date FROM works ORDER BY purchase_date DESC;")

            if [ ${#dialog_list[@]} -eq 0 ]; then
                dialog --msgbox "No records found in the database." 10 50
                continue
            fi

            selected_id=$(dialog --clear \
                --backtitle "DLsite Work Downloader" \
                --title "Recent Purchases" \
                --menu "Select a work to download (newest first):" 20 80 15 \
                "${dialog_list[@]}" \
                2>&1 >/dev/tty)

            [ $? -ne 0 ] && continue

            escaped_id="${selected_id//\'/\'\'}"
            IFS='|' read -r id name circle file_count <<< \
                "$(sqlite3 "$DB_FILE" "SELECT id, name, circle, file_count FROM works WHERE id = '$escaped_id';")"
            download_work "$id" "$name" "$circle" "$file_count"
            ;;

        # --- Download every work in the database ---
        all)
            work_count=$(sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM works;")
            dialog --yesno "Download all $work_count works?\nThis may take a long time." 10 60
            if [ $? -eq 0 ]; then
                failed=0
                while IFS=$'\t' read -r id name circle file_count; do
                    download_work "$id" "$name" "$circle" "$file_count" "false" || ((failed++))
                done < <(sqlite3 -separator $'\t' "$DB_FILE" \
                    "SELECT id, name, circle, file_count FROM works ORDER BY id;")
                if [ "$failed" -eq 0 ]; then
                    dialog --msgbox "All $work_count downloads completed successfully." 10 50
                else
                    dialog --msgbox "$failed of $work_count download(s) failed." 10 50
                fi
            fi
            ;;

    esac
done
clear

