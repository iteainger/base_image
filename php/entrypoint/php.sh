# init.sh already runs as root; do not go through sudo, it resets the env
# (UPLOAD_MAX_FILESIZE, PHP_FPM_SERVERS, PHP_DEBUG, ...) that setup-php reads.
if [[ -f /setup-php ]]; then
    bash /setup-php
    touch "/setup-php.$(date -Is)"
fi

/usr/sbin/php-fpm > /proc/1/fd/1 2>&1 &
echo -n "$! " | sudo tee -a /var/run/services > /dev/null

for _ in $(seq 1 50); do
    [[ -S /var/run/php/php-fpm.sock ]] && break
    sleep 0.2
done

cfg=${CONFIGFILE:-/etc/ferron.conf}
echo "Starting ferron with config ${cfg}"
/usr/local/bin/ferron run --config "$cfg" > /proc/1/fd/1 2>&1 &
echo -n "$! " | sudo tee -a /var/run/services > /dev/null