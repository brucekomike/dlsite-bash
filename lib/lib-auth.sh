function dlsite-skip-register(){
    # https://www.dlsite.com/maniax/login/=/skip_register/1
    RESULT=$(curl -fsSL -X GET \
    -c cookie.txt \
    -b cookie.txt \
    "https://www.dlsite.com/maniax/login/=/skip_register/1")
}
function dlsite-refresh-csrf(){
    # https://login.dlsite.com/login
    RESULT=$(curl -fsSL -X GET \
    -c cookie.txt \
    -b cookie.txt \
    "https://login.dlsite.com/login")
}

function read-csrf(){
    # https://www.dlsite.com/maniax/login/=/skip_register/1
    cat cookie.txt | grep "XSRF-TOKEN" | awk '{print $7}'
}

function dlsite-login(){
    # https://login.dlsite.com/login
    # login_id username
    # password password
    RESULT=$(curl -fsSL -X POST \
    -d login_id="$1" \
    -d password="$2" \
    -d _token="$(read-csrf)" \
    -c cookie.txt \
    -b cookie.txt \
    "https://login.dlsite.com/login")
    echo "$RESULT"
}
