# dropbear sshd: ed25519_<user>=<pubkey>, <user> = name:uid:gid[:comment]
# SSH_HOSTKEY_ED25519: base64 encoded ed25519 host key
# SSH_TIMEOUT: idle/kill timeout in seconds
# SSH_SUDO_GROUP: group added for new users (default "sudo")
#
# Same env contract as xy entrypoint/ssh.nu.

if [[ -e /bin/zsh ]]; then
    __shell=/bin/zsh
elif [[ -e /bin/bash ]]; then
    __shell=/bin/bash
else
    __shell=/bin/sh
fi

set_user () {
    IFS=':' read -ra ARR <<< "$1"
    local name=${ARR[0]}
    local uid=${ARR[1]:-1000}
    local gid=${ARR[2]:-$uid}
    local comment=${ARR[3]:-$name}
    local sudo_group=${SSH_SUDO_GROUP:-sudo}

    if [[ $name == 'root' ]]; then
        uid=0
        gid=0
    else
        getent group "$name" > /dev/null 2>&1 || sudo groupadd -g "$gid" "$name"
        getent passwd "$name" > /dev/null 2>&1 \
            || sudo useradd -m -u "$uid" -g "$gid" -G "$sudo_group" -s "$__shell" -c "$comment" "$name"
    fi

    local home_dir
    home_dir=$(getent passwd "$name" | cut -d: -f6)

    printf '\nexport PATH=%s\n' "$PATH" | sudo tee -a "$home_dir/.profile" > /dev/null

    local ssh_dir=$home_dir/.ssh
    sudo mkdir -p "$ssh_dir"
    echo "ssh-ed25519 $2" | sudo tee -a "$ssh_dir/authorized_keys" > /dev/null
    sudo chown -R "$name:$name" "$ssh_dir"
    sudo chmod -R go-rwx "$ssh_dir"
}

init_ssh () {
    if [[ -n "${SSH_HOSTKEY_ED25519}" ]]; then
        echo "$SSH_HOSTKEY_ED25519" | base64 -d \
            | sudo tee /etc/dropbear/dropbear_ed25519_host_key > /dev/null
        sudo chmod 600 /etc/dropbear/dropbear_ed25519_host_key
    fi

    local i
    for i in "$@"; do
        set_user "${i:8}" "${!i}"
    done
}

run_ssh () {
    if [[ -z "${SSH_TIMEOUT}" ]]; then
        echo "Starting dropbear"
        sudo dropbear -REFems -p 22 > /proc/1/fd/1 2>&1 &
    else
        echo "Starting dropbear with a timeout of ${SSH_TIMEOUT} seconds"
        sudo dropbear -REFems -p 22 -K "${SSH_TIMEOUT}" -I "${SSH_TIMEOUT}" > /proc/1/fd/1 2>&1 &
    fi
    echo -n "$! " | sudo tee -a /var/run/services > /dev/null
}

mapfile -t __ssh < <(compgen -A variable ed25519_)
if [[ ${#__ssh[@]} -gt 0 ]]; then
    sudo mkdir -p /etc/dropbear
    init_ssh "${__ssh[@]}"
    run_ssh
fi