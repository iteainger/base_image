# Add users if $1=user:uid:gid set
if [[ -e /bin/zsh ]]; then
    __shell=/bin/zsh
elif [[ -e /bin/bash ]]; then
    __shell=/bin/bash
else
    __shell=/bin/sh
fi

# $1 = name[:uid[:gid[:comment]]], $2 = the ed25519 public key
set_user () {
    IFS=':' read -ra ARR <<< "$1"
    local _NAME=${ARR[0]}
    local _KEY=$2
    local _UID _GID _COMMENT
    if [[ ${_NAME} == "root" ]]; then
        _UID=0
        _GID=0
    else
        _UID=${ARR[1]:-1000}
        _GID=${ARR[2]:-$_UID}
        _COMMENT=${ARR[3]:-$_NAME}

        sudo getent group ${_NAME} >/dev/null 2>&1 || sudo groupadd -g ${_GID} ${_NAME}
        sudo getent passwd ${_NAME} >/dev/null 2>&1 || sudo useradd -m -u ${_UID} -g ${_GID} -G ${SSH_SUDO_GROUP:-sudo} -s ${__shell} -c "${_COMMENT}" ${_NAME}
    fi

    local _HOME_DIR
    _HOME_DIR=$(getent passwd ${_NAME} | cut -d: -f6)

    local _PROFILE="${_HOME_DIR}/.profile"
    { \
        echo "" ;\
        echo "export PATH=$PATH" ;\
    } | sudo tee -a ${_PROFILE} > /dev/null

    sudo mkdir -p ${_HOME_DIR}/.ssh
    echo "ssh-ed25519 $_KEY" | sudo tee -a ${_HOME_DIR}/.ssh/authorized_keys > /dev/null
    sudo chown ${_NAME} -R ${_HOME_DIR}/.ssh
    sudo chmod go-rwx -R ${_HOME_DIR}/.ssh
}

init_ssh () {
    if [[ -n "$SSH_HOSTKEY_ED25519" ]]; then
        # tee keeps umask's 644; a private host key must not be group/world
        # readable, and dropbear does not tighten it for us.
        echo "$SSH_HOSTKEY_ED25519" | base64 -d \
        | sudo tee /etc/dropbear/dropbear_ed25519_host_key > /dev/null
        sudo chmod 600 /etc/dropbear/dropbear_ed25519_host_key
    fi

    for i in "${!ed25519_@}"; do
        _USER=${i:8}
        set_user "${_USER}" "${!i}"
    done
}

# dropbear writes to PID 1's stdout so its log lands in the container log.
run_ssh () {
    if [[ -z "$SSH_TIMEOUT" ]]; then
        echo "starting dropbear"
        sudo dropbear -REFems -p 22 >> /proc/1/fd/1 2>&1 &
    else
        echo "starting dropbear with a timeout of ${SSH_TIMEOUT} seconds"
        sudo dropbear -REFems -p 22 -K ${SSH_TIMEOUT} -I ${SSH_TIMEOUT} >> /proc/1/fd/1 2>&1 &
    fi
    # Direct redirect, no pipe: $! must be the dropbear PID (see s3fs.sh).
    echo -n "$! " | sudo tee -a /var/run/services > /dev/null
}

__ssh=$(for i in "${!ed25519_@}"; do echo $i; done)
if [[ -n "$__ssh" ]]; then
    sudo mkdir -p /etc/dropbear
    init_ssh
    run_ssh
fi
