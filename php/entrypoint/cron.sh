if [[ -n "${CRONFILE}" ]]; then
    sudo crontab ${CRONFILE}
    sudo cron
fi
