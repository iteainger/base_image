# s3fs: s3_<id>=mount,user,endpoint,region,bucket,accesskey,secretkey,opts...
# opts: nonempty,use_path_request_style,use_xattr,a=1,b=2
#
# Same env contract as xy entrypoint/s3fs.nu.

run_s3 () {
    IFS=',' read -ra ARR <<< "$2"
    local mount=${ARR[0]}
    local user=${ARR[1]:-root}
    local endpoint=${ARR[2]}
    local region=${ARR[3]}
    local bucket=${ARR[4]}
    local accesskey=${ARR[5]}
    local secretkey=${ARR[6]}

    local -a opt=()
    local i
    for i in "${ARR[@]:7}"; do
        opt+=(-o "$i")
    done

    local name=${mount//\//_}
    local auth_dir=/.s3fs-passwd
    local auth_file=$auth_dir/$name
    local logfile=/var/log/s3fs_${name}

    sudo mkdir -p $auth_dir
    echo "authfile $auth_file"
    printf '%s:%s\n' "$accesskey" "$secretkey" | sudo tee $auth_file > /dev/null
    sudo chmod go-rwx $auth_file
    sudo chown "$user" $auth_file

    sudo mkdir -p "$mount"
    sudo chown "$user" "$mount"

    local -a region_opt=(-o use_path_request_style)
    if [[ -n "$region" ]]; then
        region_opt=(-o "endpoint=$region")
    fi

    echo "starting s3fs $1 on $mount"
    sudo -u "$user" s3fs -f "${opt[@]}" \
        -o "bucket=$bucket" \
        -o "passwd_file=$auth_file" \
        -o "url=$endpoint" \
        "${region_opt[@]}" "$mount" >> $logfile 2>&1 &
    echo -n "$! " | sudo tee -a /var/run/services > /dev/null
}

mapfile -t __s3 < <(compgen -A variable s3_)
for i in "${__s3[@]}"; do
    run_s3 "${i:3}" "${!i}"
done