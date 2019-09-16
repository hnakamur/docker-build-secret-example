docker-build-secret-example
===========================

## Prerequisite: about docker build --secret

### docker build --secret exists for API version 1.39+

`docker build` has [`--secret` option for API version 1.39+](https://docs.docker.com/engine/reference/commandline/build/#options).

### API version 1.39+ means docker 18.09.0+
In release notes, under "New features for Docker Engine EE and CE" section at [18.09.0](https://docs.docker.com/engine/release-notes/#18090) says:

 * Updated API version to 1.39 moby/moby#37640

### "Build Enhancements for Docker" page in guides has a bit outdated explanation.

I found `--secret` option at [New Docker Build secret information](https://docs.docker.com/develop/develop-images/build_enhancements/#new-docker-build-secret-information), but the explanation here turned out to be outdated.
It says

> This Dockerfile is only to demonstrate that the secret can be accessed. As you can see the secret printed in the build output. The final image built will not have the secret file

but actually the secret is not printed in the build output. I think it is guarded for security.

### "Dockerfile frontend experimental syntaxes" page in buildkit has up-to-date explanation.

Then I found the following page.

 * [buildkit/experimental.md at master ・ moby/buildkit](https://github.com/moby/buildkit/blob/master/frontend/dockerfile/docs/experimental.md)
 * [buildkit/experimental.md at 1bf8190 ・ moby/buildkit](https://github.com/moby/buildkit/blob/1bf81905fee37175099507fa82c372f6a490cacd/frontend/dockerfile/docs/experimental.md) as of writing this.

### How to use `docker build --secret`

Here is the steps to follow.

1. Make sure you use the required version of docker.

```
$ docker version
Client: Docker Engine - Community
 Version:           19.03.2
 API version:       1.40
 Go version:        go1.12.8
 Git commit:        6a30dfc
 Built:             Thu Aug 29 05:29:11 2019
 OS/Arch:           linux/amd64
 Experimental:      false

Server: Docker Engine - Community
 Engine:
  Version:          19.03.2
  API version:      1.40 (minimum version 1.12)
  Go version:       go1.12.8
  Git commit:       6a30dfc
  Built:            Thu Aug 29 05:27:45 2019
  OS/Arch:          linux/amd64
  Experimental:     false
 containerd:
  Version:          1.2.6
  GitCommit:        894b81a4b802e4eb2a91d1ce216b8817763c29fb
 runc:
  Version:          1.0.0-rc8
  GitCommit:        425e105d5a03fabd737a126ad93d62a9eeede87f
 docker-init:
  Version:          0.18.0
  GitCommit:        fec3683
```

 2. Set `DOCKER_BUILDKIT` environment variable to `1`

```
$ export DOCKER_BUILDKIT=1
```

 3. Create a secret file.

```
$ echo "It's a secret" > mysecret.txt
```

 4. Create a Dockerfile.

```
$ cat <<EOF > Dockerfile
# syntax = docker/dockerfile:experimental
FROM alpine
RUN --mount=type=secret,id=mysecret,target=/foobar cat /foobar | tee /output
EOF
```
Make sure you have `# syntax = docker/dockerfile:experimental` at the first line in `Dockerfile`.
Note the above example is just for demo. You should not save the content of secret in actual usage.


5. Run `docker build` with `--secret` option.

```
$ docker build -t secret-example --secret id=mysecret,src=mysecret.txt .
[+] Building 2.3s (8/8) FINISHED
 => [internal] load build definition from Dockerfile
 => => transferring dockerfile: 176B
 => [internal] load .dockerignore
 => => transferring context: 2B
 => resolve image config for docker.io/docker/dockerfile:experimental
 => CACHED docker-image://docker.io/docker/dockerfile:experimental@sha256:888f21826273409b5ef5ff9ceb90c64a8f8ec7760da30d1ffbe6c3e2d323a7bd
 => [internal] load metadata for docker.io/library/alpine:latest
 => CACHED [1/2] FROM docker.io/library/alpine
 => [2/2] RUN --mount=type=secret,id=mysecret,target=/foobar cat /foobar | tee /output
 => exporting to image
 => => exporting layers
 => => writing image sha256:22c44473107b6d1f92095c6400613a7e82c9835f5baaa85853a114e4bb5d8744
 => => naming to docker.io/library/secret-example
```

Note the content of `mysecret.txt` is NOT printed even in the build output.

Verify the secret is correctly used. Again this is just for demo purpose.

```
$ docker run -t secret-example cat /output
It's a secret
```

I noticed the content of `/foobar` is not saved, but empty file remains in the built image.

```
$ docker run -t secret-example ls -l /foobar
-rwxr-xr-x    1 root     root             0 Sep 16 19:16 /foobar
```

## About this example: gpg clearsign during docker build

### Prerequisite

Install gnupg on your host and generate or import a secret key.


### Set up secret files to pass to docker build.

Show the fingerprint for your secret key.

```
$ gpg --list-secret-keys
/home/hnakamur/.gnupg/pubring.gpg
---------------------------------
sec   rsa4096 2015-11-14 [SC] [expires: 2020-03-25]
      XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
uid           [ultimate] Hiroaki Nakamura <hnakamur@gmail.com>
ssb   rsa4096 2015-11-14 [E] [expires: 2020-03-25]
```

Set the fingerprint to an environment variable for later use.

```
$ export GPG_FINGERPRINT=XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
```

Export your secret key to file.

```
$ gpg --export-secret-keys $GPG_FINGERPRINT > my-gpg-secret-key
```

Save your passphrase for the secret key.

```
$ echo 'YOUR PASSPHRASE HERE' > my-gpg-passphrase.txt
```

### Run docker build with --secret options

```
docker build -t secret-example \
  --secret id=gpgsecretkey,src=my-gpg-secret-key \
  --secret id=gpgpassphrase,src=my-gpg-passphrase.txt \
  --build-arg GPG_SECRET_KEY_FINGERPRINT=$GPG_FINGERPRINT \
  .
```

### Use signature in the docker image to verify the input file on the host

```
$ docker run -it secret-example cat /data/file1.asc | gpg --verify
gpg: Signature made Tue 17 Sep 2019 05:40:34 AM JST
gpg:                using RSA key XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
gpg: Good signature from "Hiroaki Nakamura <hnakamur@gmail.com>" [ultimate]
```
