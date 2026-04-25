if [ -f config.sh ]; then
    source config.sh
else
    echo "config.sh not found. Please create config.sh with your login credentials."
    cp config.sh.example config.sh
    exit 1
fi