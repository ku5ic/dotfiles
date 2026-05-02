#!/bin/bash

env=$1
APP_DIR=/var/www/myapp
TARGET_DIR=/var/www/myapp/releases/$(date +%s)

if [ $env = "prod" ]; then
    BRANCH=main
else
    BRANCH=develop
fi

echo "Deploying $BRANCH to $env"

mkdir /tmp/deploy-temp
cd /tmp/deploy-temp
git clone --depth 1 --branch $BRANCH git@github.com:acme/myapp.git source

cd /var/www/myapp
git pull origin $BRANCH

VERSION=$(cat /tmp/deploy-temp/source/config.yml | grep version | awk '{print $2}')
echo "Building version $VERSION"

mkdir -p $TARGET_DIR
cp -r /tmp/deploy-temp/source/* $TARGET_DIR/

for f in $(ls /var/log/myapp); do
    if [ -f /var/log/myapp/$f ]; then
        gzip /var/log/myapp/$f
    fi
done

ln -sfn $TARGET_DIR $APP_DIR/current

systemctl restart myapp

PREV_DIR=$(ls -t $APP_DIR/releases | tail -n +6)
for d in $PREV_DIR; do
    rm -rf "$APP_DIR/releases/$d/"
done

rm -rf "$TARGET_DIR/"

echo "Deploy complete"
