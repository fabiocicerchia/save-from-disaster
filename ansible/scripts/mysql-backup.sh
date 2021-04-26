#!/bin/bash

USER=user
PASSWD=password

mkdir -p /var/backups/{hourly,daily,weekly,monthly}

if [[ "$(find "/var/backups/hourly/alldb.sql.gz.enc" -empty -or -mmin +60 2>&1)" != "" ]]; then
    openssl rand -base64 32 > key.bin
    openssl rsautl -encrypt -inkey /root/.ssh/backup.pub -pubin -in key.bin -out /var/backups/hourly/key.enc
    mysqldump -u$USER -p$PASSWD --single-transaction --all-databases | gzip -9f | openssl enc -aes-256-cbc -salt -out /var/backups/hourly/alldb.sql.gz.enc -pass file:./key.bin
    rm key.bin

    # openssl rsautl -decrypt -inkey backup.pem -in key.enc -out key.bin
    # openssl enc -d -aes-256-cbc -in alldb.sql.gz.enc -out alldb.sql.gz -pass file:./key.bin
fi

if [[ "$(find "/var/backups/daily/alldb.sql.gz.enc" -mmin +1440 2>&1)" != "" ]]; then
    cp -v /var/backups/hourly/key.enc /var/backups/daily/key.enc
    cp -v /var/backups/hourly/alldb.sql.gz.enc /var/backups/daily/alldb.sql.gz.enc
fi

if [[ "$(find "/var/backups/weekly/alldb.sql.gz.enc" -mmin +10080 2>&1)" != "" ]]; then
    cp -v /var/backups/hourly/key.enc /var/backups/weekly/key.enc
    cp -v /var/backups/hourly/alldb.sql.gz.enc /var/backups/weekly/alldb.sql.gz.enc
fi

if [[ "$(find "/var/backups/monthly/alldb.sql.gz.enc" -mmin +302400 2>&1)" != "" ]]; then
    cp -v /var/backups/hourly/key.enc /var/backups/monthly/key.enc
    cp -v /var/backups/hourly/alldb.sql.gz.enc /var/backups/monthly/alldb.sql.gz.enc
fi
