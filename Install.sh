#!/bin/sh

PATH_IN_ETC_SV="/etc/sv/FileBrowserQuantum"
PATH_IN_VAR_SERVICE="/var/service/FileBrowserQuantum"
PATH_IN_LOCAL="/home/fus/.fus/Applications/FileBrowserQuantum"
SV_NAME="FileBrowserQuantum"
DEFAULT_PERMISSION=755
set -e

##########################################################################################
PrepareDir() {
    # Validate argument count
    if ! [ $# -eq 1 ]; then 
        Info "$LINENO" "Required ONLY ONE ARG! E.g: PrepareDir \"path/to/a/dir\"!"
        exit 1
    fi
    # Ensure the path is not a regular file
    if [ -f "$1" ]; then 
        Info "$LINENO" "Required a DIRECTORY path! E.g: PrepareDir \"path/to/a/dir\"!"
    fi
    # Clean existing directory if present
    if [ -e "$1" ]; then
        Info "$LINENO" "\"$1\" exists! ---> Remove!"
        sudo rm -rf "$1"
    fi
    sudo mkdir -p "$1"
    sudo chmod "$DEFAULT_PERMISSION" "$1"
}

# Compatibility alias
PrepairDir() {
    PrepareDir "$@"
}
##########################################################################################
Info() {
    local line="$1"
    shift
    echo "[Install.sh:$line] $@"
}
##########################################################################################

Info "$LINENO" "Validate sudo timestamp..."
sudo -v
EXIT_CODE=$?

# Control flow for checking sudo elevation result
if [ $EXIT_CODE -ne 0 ]; then
    Info "$LINENO" "Failed to take SUDO permission! CODE=$EXIT_CODE"
    exit 1
fi

Info "$LINENO" "Clean/Prepare install directory"
if [ -e "$PATH_IN_VAR_SERVICE" ]; then
    Info "$LINENO" "'$PATH_IN_VAR_SERVICE' exists."
    if sudo sv status "$SV_NAME" > /dev/null 2>&1; then 
        Info "$LINENO" "Stop '$SV_NAME'..."
        sudo sv stop "$SV_NAME" || true
    fi
    Info "$LINENO" "Remove $PATH_IN_VAR_SERVICE..."
    sudo rm -rf "$PATH_IN_VAR_SERVICE"
fi

if [ -e "$PATH_IN_ETC_SV" ]; then
    Info "$LINENO" "'$PATH_IN_ETC_SV' exists! --> Remove!"
    sudo rm -rf "$PATH_IN_ETC_SV"
fi

Info "$LINENO" "Deploy service definition to '$PATH_IN_ETC_SV'"
if [ ! -d "$PATH_IN_LOCAL" ]; then
    Info "$LINENO" "Not found '$PATH_IN_LOCAL' --> Aborted!"
    exit 1
fi

# Ensure local run scripts are executable
chmod +x "$PATH_IN_LOCAL/run"
if [ -f "$PATH_IN_LOCAL/log/run" ]; then
    chmod +x "$PATH_IN_LOCAL/log/run"
fi

# Create runit service directory and copy service scripts
sudo mkdir -p "$PATH_IN_ETC_SV/log"
sudo cp -f "$PATH_IN_LOCAL/run" "$PATH_IN_ETC_SV/run"
sudo chmod 755 "$PATH_IN_ETC_SV/run"

if [ -f "$PATH_IN_LOCAL/log/run" ]; then
    sudo cp -f "$PATH_IN_LOCAL/log/run" "$PATH_IN_ETC_SV/log/run"
    sudo chmod 755 "$PATH_IN_ETC_SV/log/run"
fi

Info "$LINENO" "Enable $SV_NAME"
sudo ln -s "$PATH_IN_ETC_SV" "$PATH_IN_VAR_SERVICE"
EXIT_CODE=$?
if [ $EXIT_CODE -ne 0 ]; then
    Info "$LINENO" "Failed to ENABLE! CODE=$EXIT_CODE ---> Aborted!"
    exit 1
fi

Info "$LINENO" "Waiting for runsv to register $SV_NAME..."
sleep 2

Info "$LINENO" "Start/Restart $SV_NAME"
sudo sv restart "$SV_NAME" || sudo sv up "$SV_NAME"
EXIT_CODE=$?
if [ $EXIT_CODE -ne 0 ]; then
    Info "$LINENO" "Failed to START! CODE=$EXIT_CODE ---> Aborted!"
    exit 1
fi

Info "$LINENO" "$SV_NAME service deployed and running successfully!"
