#!/bin/sh

NGINX_CONFIGS_PATH=/etc/nginx/conf.d
NGINX_AVAILABLE_CONFIGS_PATH=/etc/nginx/conf.d-available
RED="\033[0;31m"
NC="\033[0m"

# Helper function that sifts through /etc/nginx/conf.d-available/, making symlinks
# and call 'nginx -t' for testing config. If new config contain errors symlink will be removed
enable_disable_configs() {
    $(remove_conf_symlinks)
    for config_file in ${NGINX_AVAILABLE_CONFIGS_PATH}/*.conf; do
        file_name=${config_file##*/}
        ln -sf ${config_file} "${NGINX_CONFIGS_PATH}/${file_name}"
        if ! is_config_valid; then
            rm ${NGINX_CONFIGS_PATH}/${file_name}
        fi
    done
}

remove_conf_symlinks() {
    find ${NGINX_CONFIGS_PATH}/*.conf -type l -delete
}

is_config_valid() {
    nginx -t
    return $?
}

# Helper function to output error messages to STDERR, with red text
error() {
    (echo -e "${RED}${1}${NC}") >&2
}

# Helper function that sifts through /etc/nginx/conf.d/, looking for lines that
# contain ssl_certificate_key, and try to find domain names in them.  We accept
# a very restricted set of keys: Each key must map to a set of concrete domains
# (no wildcards) and each keyfile will be stored at the default location of
# /etc/letsencrypt/live/<primary_domain_name>/privkey.pem
parse_domains() {
    # For each configuration file in /etc/nginx/conf.d/*.conf
    for config_file in ${NGINX_AVAILABLE_CONFIGS_PATH}/*.conf; do
        sed -n -e 's&^\s*ssl_certificate_key\s*\/etc/letsencrypt/live/\(.*\)/privkey.pem;&\1&p' ${config_file} | xargs echo | tr ' ' ','
    done
}

# Helper function to ask certbot for the given domain(s).  Must have defined the
# EMAIL environment variable, to register the proper support email address.
get_certificate() {
    if [ -z "${DRY_RUN}" ]; then
        DRY_RUN=""
    else
        DRY_RUN="--dry-run"
    fi
    if [ -z "${DEBUG}" ]; then
        DEBUG=""
    else
        DEBUG="--debug"
    fi
    echo "Getting certificate for domain $1 on behalf of user $2"
    certbot certonly --domain $1 --email $2 ${DEBUG} ${DRY_RUN}
}
