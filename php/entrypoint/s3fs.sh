# s3fs if s3_id=mount,user,endpoint,region,bucket,accesskey,secretkey,opts...
# opts: nonempty,use_path_request_style,use_xattr,a=1,b=2

run_s3 () {
    IFS=',' read -ra ARR <<< "$2"
    local _mount=${ARR[0]}
    local _user=${ARR[1]:-root}
    local _endpoint=${ARR[2]}
    local _region=${ARR[3]}
    local _bucket=${ARR[4]}
    local _accesskey=${ARR[5]}
    local _secretkey=${ARR[6]}

    local -a _opt=()
    local i
    for i in "${ARR[@]:7}"; do
        _opt+=(-o "$i")
    done

    local name=${_mount////_}
    local logfile=/var/log/s3fs_${name}

    if [[ ! -d /.s3fs-passwd ]]; then
        sudo mkdir /.s3fs-passwd
    fi
    local _authfile=/.s3fs-passwd/$name
    echo authfile $_authfile

    echo "${_accesskey}:${_secretkey}" | sudo tee $_authfile > /dev/null
    sudo chmod go-rwx $_authfile
    sudo chown $_user $_authfile
    sudo mkdir -p $_mount
    sudo chown $_user $_mount

    local -a _region_opt=(-o use_path_request_style)
    if [[ -n "${_region}" ]]; then
        _region_opt=(-o "endpoint=${_region}")
    fi

    # Built as an array, not a string: an option or secret carrying spaces,
    # quotes or `$(...)` must reach s3fs literally, never through the shell.
    local -a _cmd=(sudo -u "${_user}" s3fs -f "${_opt[@]}"
        -o "bucket=$_bucket" -o "passwd_file=$_authfile" -o "url=$_endpoint"
        "${_region_opt[@]}" "$_mount")
    echo "${_cmd[*]}"
    # Direct redirect, no pipe: $! must be the s3fs PID, otherwise the pid
    # recorded below is the logger's and the mount's death goes unnoticed.
    "${_cmd[@]}" >> $logfile 2>&1 &
    echo -n "$! " | sudo tee -a /var/run/services > /dev/null
}

__s3=$(for i in "${!s3_@}"; do echo $i; done)
if [[ -n "$__s3" ]]; then
    for i in "${!s3_@}"; do
        _ID=${i:3}
        echo "starting s3fs $_ID"
        run_s3 "$_ID" "${!i}"
    done
fi
