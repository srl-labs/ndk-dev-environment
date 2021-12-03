#!/bin/bash
###########################################################################
# Description:
#     This script will launch the python script of the {{ getenv "APPNAME" }} agent
#     (forwarding any arguments passed to this script).
###########################################################################


_term (){
    echo "Caugth signal SIGTERM !! "
    kill -TERM "$child" 2>/dev/null
}

function main()
{
    trap _term SIGTERM
    local virtual_env="/opt/{{ getenv "APPNAME" }}/.venv/bin/activate"
    local main_module="/opt/{{ getenv "APPNAME" }}/main.py"

    # source the virtual-environment, which is used to ensure the correct python packages are installed,
    # and the correct python version is used
    source "${virtual_env}"

    python3 ${main_module} &

    child=$!
    wait "$child"
}

main "$@"