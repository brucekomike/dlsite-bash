#!/bin/bash

source load.sh

dlsite-refresh-csrf
dlsite-skip-register
dlsite-login "$username" "$password"