#!/bin/bash

NAMESPACE=$1
DOMAINS=(
example.com
)

cd /tmp

for DOMAIN in ${DOMAINS[@]}; do
    wget --mirror https://$DOMAIN
    aws s3 sync $DOMAIN s3://$NAMESPACE-website-static-$DOMAIN/
    rm -rf $DOMAIN
done
