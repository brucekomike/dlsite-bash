function dlsite-get-download-link(){
    # https://play.dlsite.com/api/v3/content/download?workno={}
    RESULT=$(curl -fsSL -X GET \
    -c cookie.txt \
    -b cookie.txt \
    -d _token="$(read-csrf)" \
    "https://play.dlsite.com/api/v3/content/download?workno=$1")
    echo $RESULT
}

function dlsite-download-single(){
    # https://play.dlsite.com/api/v3/download?workno={}
    curl -fSL -X GET \
    -c cookie.txt \
    -b cookie.txt \
    -d _token="$(read-csrf)" \
    "https://play.dlsite.com/api/v3/download?workno=$1" --output "$2/$1.zip"
}

function dlsite-download-multi(){
    # $1 id
    # $2 count
    # $3 output dir
    # https://play.dlsite.com/api/v3/download?workno={}
    count=1
    failed=0
    while IFS=\| read -r id file_name file_size; do
        curl -fSL -X GET \
        -c cookie.txt \
        -b cookie.txt \
        -d _token="$(read-csrf)" \
        https://www.dlsite.com/maniax/download/=/number/$count/product_id/$id.html \
        --output "$3/$file_name"
        curl_rc=$?
        if [ $curl_rc -ne 0 ] || [ ! -s "$3/$file_name" ]; then
            echo "Download failed for $file_name" >&2
            failed=1
        elif [ -n "$file_size" ] && [ "$file_size" -gt 0 ] 2>/dev/null; then
            actual_size=$(wc -c < "$3/$file_name")
            if [ "$actual_size" -ne "$file_size" ]; then
                echo "Size mismatch for $file_name: expected $file_size bytes, got $actual_size bytes" >&2
                failed=1
            fi
        fi
        ((count++))
    done < <(dlsite-get-download-list $1)
    return $failed
}

function dlsite-get-download-list(){
    RESULT=$(dlsite-get-work-info-plain $1)
    echo $RESULT | jq -r '.[] | .contents |.[]' | jq -r '"\(.workno)|\(.file_name)|\(.file_size)"'
}


