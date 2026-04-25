function dlsite-get-download-link(){
    # https://play.dlsite.com/api/v3/content/download?workno={}
    RESULT=$(curl -fsSL -X GET \
    -c cookie.txt \
    -b cookie.txt \
    -d _token="$(read-csrf)" \
    "https://play.dlsite.com/api/v3/content/download?workno=$1")
    echo $RESULT
}

function dlsite-download-product(){
    # https://play.dlsite.com/api/v3/download?workno={}
    curl -fSL -X GET \
    -c cookie.txt \
    -b cookie.txt \
    -d _token="$(read-csrf)" \
    "https://play.dlsite.com/api/v3/download?workno=$1" --output "$2"
}