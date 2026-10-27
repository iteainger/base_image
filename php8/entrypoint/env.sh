# Persist container env into /etc/environment so login shells and cron jobs see
# it. Same key filter as xy entrypoint/env.nu.

env \
    | grep -E '_|HOME|ROOT|PATH|TIMEZONE|HOSTNAME|DIR|VERSION|LANG|TIME|MODULE|BUFFERED' \
    | grep -Ev '^(NU_|PROMPT_COMMAND|ENV_CONVERSIONS|PATH|PROCESS_PATH|_|HOME|USER|LS_COLORS)=' \
    | sudo tee -a /etc/environment > /dev/null