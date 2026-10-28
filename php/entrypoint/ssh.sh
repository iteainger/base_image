# Add users if $1=user:uid:gid set
if [[ -e /bin/zsh ]]; then
    __shell=/bin/zsh
elif [[ -e /bin/bash ]]; then
    __shell=/bin/bash
else
    __shell=/bin/sh
fi

set_user () {
    IFS=':' read -ra ARR <<< "$1"
    _NAME=${ARR[0]}
    if [[ ${_NAME} == "root" ]]; then
        _UID=0
        _GID=0
    else
        _UID=${ARR[1]:-1000}
        _GID=${ARR[2]:-1000}

        sudo getent group ${_NAME} >/dev/null 2>&1 || sudo groupadd -g ${_GID} ${_NAME}
        sudo getent passwd ${_NAME} >/dev/null 2>&1 || sudo useradd -m -u ${_UID} -g ${_GID} -G sudo -s ${__shell} -c "$2" ${_NAME}
    fi

    _HOME_DIR=$(getent passwd $1 | cut -d: -f6)

    _PROFILE="${_HOME_DIR}/.profile"
    { \
        echo "" ;\
        echo "PATH=$PATH" ;\
    } | sudo tee -a ${_PROFILE} > /dev/null

    sudo mkdir -p ${_HOME_DIR}/.ssh
    echo "ssh-ed25519 $3" | sudo tee -a ${_HOME_DIR}/.ssh/authorized_keys > /dev/null
    sudo chown ${_NAME} -R ${_HOME_DIR}/.ssh
    sudo chmod go-rwx -R ${_HOME_DIR}/.ssh
}

init_ssh () {
    if [[ -n "$SSH_HOSTKEY_ED25519" ]]; then
        echo "$SSH_HOSTKEY_ED25519" | base64 -d \
        | sudo tee /etc/dropbear/dropbear_ed25519_host_key
    fi

    for i in "${!ed25519_@}"; do
        _USER=${i:8}
        _KEY=$(eval "echo \$$i")
        set_user ${_USER} 'SSH User' ${_KEY}
    done
}

run_ssh () {
    local logfile
    if [[ -n "$stdlog" ]]; then
        logfile=/dev/stdout
    else
        logfile=/var/log/sshd
    fi

    if [[ -z "$SSH_TIMEOUT" ]]; then
        echo "starting dropbear"
        sudo /usr/bin/dropbear -REFems -p 22 2>&1 | sudo tee -a $logfile > /dev/null &
    else
        echo "starting dropbear with a timeout of ${SSH_TIMEOUT} seconds"
        sudo /usr/bin/dropbear -REFems -p 22 -K ${SSH_TIMEOUT} -I ${SSH_TIMEOUT} 2>&1 | sudo tee -a $logfile > /dev/null &
    fi
    echo -n "$! " | sudo tee -a /var/run/services > /dev/null
}

__ssh=$(for i in "${!ed25519_@}"; do echo $i; done)
if [[ -n "$__ssh" ]]; then
    sudo mkdir -p /etc/dropbear
    init_ssh
    run_ssh
fi
