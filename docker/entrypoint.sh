#! /bin/bash
set +e
read -r -d '' RUN_COMMANDS <<-'EOF'
./start_pr.sh +multi 1 +dedicated 1
echo "Server stopped. Exit shell to clean up."
exec </dev/tty
EOF

bash -ic $RUN_COMMANDS
