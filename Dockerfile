FROM nginx:alpine

VOLUME /etc/letsencrypt
EXPOSE 80
EXPOSE 443

COPY config/nginx-deafult.conf /etc/nginx/conf.d/default.conf
COPY config/certbot.ini /root/.config/letsencrypt/cli.ini
COPY config/crontab /etc/cron.d/certbot
COPY scripts/ /scripts

# Do this apt/pip stuff all in one RUN command to avoid creating large
# intermediate layers on non-squashable docker installs
RUN apk add --update --no-cache \
        certbot \
        openssl \
    # Update crontab
    && crontab /etc/cron.d/certbot \
    && chmod +x /scripts/*.sh \
    # Make directory for "/.well-known/acme-challenge/" validation
    && mkdir -p /var/www/acme/.well-known/acme-challenge \
    && mkdir -p /etc/nginx/conf.d-available

CMD ["/scripts/run.sh"]
