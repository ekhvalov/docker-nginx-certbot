#!/bin/sh

set -e

# When we get killed, kill all our children
trap "exit" INT TERM
trap "kill 0" EXIT

# Source in util.sh so we can have our nice tools
. /scripts/functions.sh

if [ ! -e ${NGINX_AVAILABLE_CONFIGS_PATH}/dhparam.pem ]; then
    openssl dhparam -out ${NGINX_AVAILABLE_CONFIGS_PATH}/dhparam.pem 2048
fi
if [ ! -e ${NGINX_CONFIGS_PATH}/dhparam.pem ]; then
    ln -s ${NGINX_AVAILABLE_CONFIGS_PATH}/dhparam.pem ${NGINX_CONFIGS_PATH}/dhparam.pem
fi

# Immediately run enable_disable_configs so that nginx is in a runnable state
enable_disable_configs

# Start up nginx, save PID so we can reload config inside of run_certbot.sh
nginx -g "daemon off;" &
export NGINX_PID=$!
# Wait little bit for nginx is started
sleep 2

# Next, run certbot to request all the ssl certs we can find
/scripts/run_certbot.sh
echo "Done with startup"

# Run `cron -f &` so that it's a background job owned by bash and then `wait`.
# This allows SIGINT (e.g. CTRL-C) to kill cron gracefully, due to our `trap`.
crond -f &
wait "$NGINX_PID"
