#!/bin/sh

PATH_IN_ETC_SV="/etc/sv/FileBrowserQuantum"
PATH_IN_VAR_SERVICE="/var/service/FileBrowserQuantum"
PATH_IN_LOCAL="/home/fus/.fus/Applications/FileBrowserQuantum"
SV_NAME="FileBrowserQuantum"
DEFAULT_PERMISSION=644
set -e

##########################################################################################
PrepairDir() {
    # Validate argument count */
    if ! [ $# -eq 1 ]; then 
        Info "$LINENO" "Required ONLY ONE ARG! E.g: PrepairDir \"path/to/a/dir\"!"
        exit 1
    fi
    # Ensure the path is not a regular file */
    if [ -f "$1" ]; then 
        Info "$LINENO" "Required a DIRECTORY path! E.g: PrepairDir \"path/to/a/dir\"!"
    fi
    # Clean existing directory if present */
    if [ -e "$1" ]; then
        Info "$LINENO" "\"$1\" is existed! ---> Remove!"
        sudo rm -vrf "$1"
    fi
    sudo mkdir -p "$1"
    sudo chmod "$DEFAULT_PERMISSION" "$1"
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

# Control flow for checking sudo elevation result */
if [ $EXIT_CODE -ne 0 ]; then
    Info "$LINENO" "Failed to take SUDO permission! CODE=$EXIT_CODE"
    exit 1
fi

Info "$LINENO" "Clean/Prepair install directory"
if [ -d $PATH_IN_VAR_SERVICE ]; then
    Info "$LINENO" "'$PATH_IN_VAR_SERVICE' is existed."
    sudo sv status FileBrowserQuantum 2&>1 > /dev/null
    EXIT_CODE=$?
    if [ $EXIT_CODE -eq 0] ; then 
        Info "$LINENO" "Stop '$SV_NAME'..."
        sudo sv stop $SV_NAME
    fi
    Info "$LINENO" "Remove $PATH_IN_VAR_SERVICE..."
    sudo rm -vrf $PATH_IN_VAR_SERVICE
fi
if [ -d $PATH_IN_ETC_SV ]; then
    Info "$LINENO" "'$PATH_IN_ETC_SV' is existed! --> Remove!"
    sudo rm -vrf $PATH_IN_ETC_SV
fi

Info "Copy '$PATH_IN_LOCAL' to '$PATH_IN_ETC_SV'"
if ! [ -e $PATH_IN_LOCAL ]; then
    Info "$LINENO" "Not found '$PATH_IN_LOCAL' --> Aborted\!"
    exit 1
fi
sudo cp -vrf $PATH_IN_LOCAL $PATH_IN_ETC_SV
EXIT_CODE=$?
if [ $EXIT_CODE -ne 0 ]; then
    Info "$LINENO" "Failed to COPY! CODE=$EXIT_CODE ---> Aborted\!"
    exit 1
fi

Info "$LINENO" "Enable $SV_NAME"
sudo ln -s /etc/sv/FileBrowserQuantum /var/service/
EXIT_CODE=$?
if [ $EXIT_CODE -ne 0 ]; then
    Info "$LINENO" "Failed to ENABLE! CODE=$EXIT_CODE ---> Aborted\!"
    exit 1
fi

Info "$LINENO" "Start $SV_NAME"
sudo sv restart $SV_NAME
EXIT_CODE=$?
if [ $EXIT_CODE -ne 0 ]; then
    Info "$LINENO" "Failed to START! CODE=$EXIT_CODE ---> Aborted\!"
    exit 1
fi

