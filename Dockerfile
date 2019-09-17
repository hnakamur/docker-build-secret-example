# syntax = docker/dockerfile:experimental
FROM alpine
RUN apk add gnupg

RUN addgroup -g 1000 -S build \
 && adduser -G build -u 1000 -S build

ADD --chown=build:build file1 /data/

ARG GPG_SECRET_KEY_FINGERPRINT

RUN --mount=type=secret,id=gpgsecretkey,target=/home/build/.gpg-secret-key,uid=1000,gid=1000 \
    --mount=type=secret,id=gpgpassphrase,target=/home/build/.gpgpassphrase,uid=1000,gid=1000 \
 gpg --batch --pinentry-mode loopback \
     --passphrase-file /home/build/.gpgpassphrase \
     --import /home/build/.gpg-secret-key \
 && gpg --batch --pinentry-mode loopback \
     --passphrase-file /home/build/.gpgpassphrase \
     --clearsign /data/file1 \
 && gpg --batch --yes --delete-secret-keys ${GPG_SECRET_KEY_FINGERPRINT} \
 && rm -rf /home/build/.gnupg
