if [[ -n "${CRONFILE}" ]]; then
    if [[ -f "${CRONFILE}" ]]; then
        sudo crontab "${CRONFILE}"
        # -f keeps cron in the foreground; plain `cron` daemonizes, so the
        # wrapper exits and the daemon escapes the pid list below.
        sudo cron -f > /proc/1/fd/1 2>&1 &
        echo -n "$! " | sudo tee -a /var/run/services > /dev/null
    else
        echo "[Error] CRONFILE: ${CRONFILE} not found."
    fi
fi
