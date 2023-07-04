FROM nginx

RUN apt-get update -qq && apt-get install -qq python3-minimal openssl openssh-client cron wget -y

RUN wget https://raw.githubusercontent.com/diafygi/acme-tiny/master/acme_tiny.py -q -O /acme_tiny.py

# 0 * * * * for hourly
RUN (crontab -l ; echo "0 * * * * /app/renew.sh > /proc/1/fd/1 2>/proc/1/fd/2") | crontab

COPY ./etc/nginx/conf.d/default.conf /etc/nginx/conf.d/default.conf
COPY ./app/ /app/

WORKDIR /data

VOLUME [ "/data" ]

ENTRYPOINT /app/entrypoint.sh
