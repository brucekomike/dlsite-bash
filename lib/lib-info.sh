function dlsite-lib-info(){
    # https://play.dlsite.com/api/v3/content/count)
    RESULT=$(curl -fsSL -X GET \
    -c cookie.txt \
    -b cookie.txt \
    -d _token="$(read-csrf)" \
    "https://play.dlsite.com/api/v3/content/count")
    TOTAL=$(jq -r .user <<< "$RESULT")
    PAGES=$(jq -r .page_limit <<< "$RESULT")
    echo "Total products: $TOTAL"
    echo "Pages: $PAGES"
}


function dlsite-get-purchased(){
    RESULT=$(curl -fsSL -X GET \
    -c cookie.txt \
    -b cookie.txt \
    -d _token="$(read-csrf)" \
    "https://play.dlsite.com/api/v3/content/sales")
    echo $RESULT
}

function dlsite-get-lib-info(){
    RESULT=$(curl -fsSL -X GET \
    -c cookie.txt \
    -b cookie.txt \
    -d _token="$(read-csrf)" \
    "https://play.dlsite.com/api/v3/content/count")
    echo $RESULT
}

function dlsite-update-lib(){
    dlsite-get-purchased | jq -r .[] | jq -r '.workno+","+.sales_date' > purchase_list.csv
}

function dlsite-get-work-info-plain(){
    # $1 id
    RESULT=$(curl -fsSL -X GET \
    -c cookie.txt \
    -b cookie.txt \
    "https://www.dlsite.com/maniax/api/=/product.json?workno=$1")
    echo $RESULT
}

function dlsite-get-work-info(){
    RESULT=$(dlsite-get-work-info-plain $1)
    echo "$RESULT" | jq -r '"\(.[] | .workno)|\(.[] | .work_name)|\(.[] | .maker_name)|\(.[] | .contents | length)"'
    # id, name, maker, remote file count
}
