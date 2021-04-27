#! /bin/bash
set +e
./start_pr.sh +multi 1 +dedicated 1 $@
echo ""
echo "Server stopped; exit the shell to clean up..."
echo ""
bash
