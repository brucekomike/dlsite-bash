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
    while IFS=\| read -r id file_name file_zile; do
        curl -fSL -X GET \
        -c cookie.txt \
        -b cookie.txt \
        -d _token="$(read-csrf)" \
        https://www.dlsite.com/maniax/download/=/number/$count/product_id/$id.html \
        --output "$3/$file_name"
        ((count++))
    done < <(dlsite-get-download-list $1)
}

function dlsite-get-download-list(){
    RESULT=$(dlsite-get-work-info-plain $1)
    echo $RESULT | jq -r '.[] | .contents |.[]' | jq -r '"\(.workno)|\(.file_name)|\(.file_size)"'
}


