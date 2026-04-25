#!/bin/bash

source load.sh

read -r -s -p "Password: " password
echo

dlsite-refresh-csrf
dlsite-skip-register
dlsite-login "$username" "$password"