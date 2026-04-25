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

function dlsite-product-list(){
    # https://play.dlsite.com/api/purchases?page=$1
    RESULT=$(curl -fsSL -X GET \
    -c cookie.txt \
    -b cookie.txt \
    -d _token="$(read-csrf)" \
    "https://play.dlsite.com/api/v3/purchases?page=$1")
    echo $RESULT
}

function dlsite-product-sale(){
    RESULT=$(curl -fsSL -X GET \
    -c cookie.txt \
    -b cookie.txt \
    -d _token="$(read-csrf)" \
    "https://play.dlsite.com/api/v3/content/sales")
    echo $RESULT
}

function dlsite-product-info(){
    RESULT=$(curl -fsSL -X GET \
    -c cookie.txt \
    -b cookie.txt \
    -d _token="$(read-csrf)" \
    "https://play.dlsite.com/api/v3/content/count")
    echo $RESULT
}

function dlsite-update-lib(){
    dlsite-product-sale | jq -r .[] | jq -r '.workno+","+.sales_date' > purchase_list.csv
}

function dlsite-get-work-info(){
    # https://www.dlsite.com/maniax/api/=/product.json?workno={}
    RESULT=$(curl -fsSL -X GET \
    -c cookie.txt \
    -b cookie.txt \
    "https://www.dlsite.com/maniax/api/=/product.json?workno=$1")
    OUTPUT=$(echo "$RESULT" | jq -r '"\(.[] | .workno),\(.[] | .work_name),\(.[] | .maker_name),\(.[] | .contents | length)"')
    # id, name, maker, remote file count
    echo -e "$OUTPUT"
}
