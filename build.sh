#!/bin/sh

export DOCKER_BUILDKIT=1

docker build -t secret-example \
  --secret id=gpgsecretkey,src=my-gpg-secret-key \
  --secret id=gpgpassphrase,src=my-gpg-passphrase.txt \
  --build-arg GPG_SECRET_KEY_FINGERPRINT=3240E02B14E15B7B5C534B81153C76601DFBC664 \
  .
