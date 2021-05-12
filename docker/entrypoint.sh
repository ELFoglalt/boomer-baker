#! /bin/bash

./start_pr.sh +multi 1 +dedicated 1
 echo ""
 echo "Server stopped. Use the command in your bash history to run it again, exit shell to clean up."
 echo ""
 history -s "./start_pr.sh +multi 1 +dedicated 1"
