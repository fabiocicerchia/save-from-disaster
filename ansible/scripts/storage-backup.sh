#!/bin/bash
NAMESPACE="xxx"
aws s3 sync --storage-class GLACIER /var/www/ s3://$NAMESPACE-storage/
