#!/bin/bash
stop () {
    kill -s QUIT $app
    kill -s QUIT $sshd
}

init_ssh () {
    for i in "${!ed25519_@}"; do
        _AU=${i:8}
        _HOME_DIR=$(getent passwd ${_AU} | cut -d: -f6)
        mkdir -p ${_HOME_DIR}/.ssh
        eval "echo \"ssh-ed25519 \$$i\" >> ${_HOME_DIR}/.ssh/authorized_keys"
        chown ${_AU} -R ${_HOME_DIR}/.ssh
        chmod go-rwx -R ${_HOME_DIR}/.ssh
    done

    # Fix permissions, if writable
    if [ -w ~/.ssh ]; then
        chown root:root ~/.ssh && chmod 700 ~/.ssh/
    fi
    if [ -w ~/.ssh/authorized_keys ]; then
        chown root:root ~/.ssh/authorized_keys
        chmod 600 ~/.ssh/authorized_keys
    fi
}

trap stop SIGINT SIGTERM SIGQUIT
dotnet ${PROJ_NAME}.dll &
app=$!

init_ssh
/usr/bin/dropbear -REFms -p 22 2>&1 &
sshd=$!

wait $sshd $app && exit $?
