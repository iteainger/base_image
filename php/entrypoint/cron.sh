if [[ -n "${CRONFILE}" ]]; then
    if [[ -f "${CRONFILE}" ]]; then
        sudo crontab "${CRONFILE}"
        sudo cron -f > /proc/1/fd/1 2>&1 &
        echo -n "$! " | sudo tee -a /var/run/services > /dev/null
    else
        echo "[Error] CRONFILE: ${CRONFILE} not found."
    fi
fi