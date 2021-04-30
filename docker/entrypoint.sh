#! /bin/bash

./start_pr.sh +multi 1 +dedicated 1
 echo "Server stopped. Exit shell to clean up docker container, or run the server again as needed."
 history -s "./start_pr.sh +multi 1 +dedicated 1"
 HISTCONTROL=ignorespace
