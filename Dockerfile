FROM nginx

RUN apt-get update -qq && \
    apt-get install -qq python3-minimal openssl openssh-client cron -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

ADD https://raw.githubusercontent.com/diafygi/acme-tiny/master/acme_tiny.py /acme_tiny.py

COPY ./etc/nginx/conf.d/default.conf /etc/nginx/conf.d/default.conf
COPY ./app/ /app/

RUN chmod +x /app/entrypoint.sh && chmod +x /app/renew.sh

# 0 * * * * for hourly
RUN (crontab -l ; echo "0 * * * * /app/renew.sh > /proc/1/fd/1 2>/proc/1/fd/2") | crontab

WORKDIR /data

VOLUME [ "/data" ]

ENTRYPOINT /app/entrypoint.sh
