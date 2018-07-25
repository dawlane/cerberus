#!/bin/sh

LOGGED_IN_USER_ID=`id -u "${USER}"`

function mod(){
    chmod -R 0775 $1
    if [ $? -ne 0 ]; then
        2>&1 echo "Failed to chmod $1 "
        exit 1
    fi
}

function own(){
    chown -R $LOGGED_IN_USER_ID:staff $1
    if [ $? -ne 0 ]; then
        2>&1 echo "Failed to chown $LOGGED_IN_USER_ID:staff $1 "
        exit 1
    fi
}

function attr(){
    xattr -rc $1
    if [ $? -ne 0 ]; then
        2>&1 echo "Failed to xattr $1 "
        exit 1
    fi
}

own "$2/Applications/{FOLDER}"
mod "$2/Applications/{FOLDER}/Cerberus.app"
mod "$2/Applications/{FOLDER}/bin"
attr "$2/Applications/{FOLDER}"

exit 0