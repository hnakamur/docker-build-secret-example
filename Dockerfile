# syntax = docker/dockerfile:experimental
FROM alpine
RUN apk add gnupg

ADD file1 /data/
ARG GPG_SECRET_KEY_FINGERPRINT

RUN --mount=type=secret,id=gpgsecretkey --mount=type=secret,id=gpgpassphrase \
 gpg --batch --pinentry-mode loopback \
     --passphrase-file /run/secrets/gpgpassphrase \
     --import /run/secrets/gpgsecretkey \
 && gpg --batch --pinentry-mode loopback \
     --passphrase-file /run/secrets/gpgpassphrase \
     --clearsign /data/file1 \
 && gpg --batch --yes --delete-secret-keys ${GPG_SECRET_KEY_FINGERPRINT} \
 && rm -rf /root/.gnupg
