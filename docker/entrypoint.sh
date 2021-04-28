#! /bin/bash
bash -i <<EOF
./start_pr.sh +multi 1 +dedicated 1
echo "Server stopped. Exit shell to clean up."
exec </dev/tty
EOF
