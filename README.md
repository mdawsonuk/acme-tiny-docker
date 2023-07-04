# acme-tiny-docker

[![Docker Image Size](https://img.shields.io/docker/image-size/mdawsonuk/acme-tiny-docker?sort=semver)](https://hub.docker.com/r/mdawsonuk/acme-tiny-docker "Click to view the image on hub.docker.com")
[![Docker stars](https://img.shields.io/docker/stars/mdawsonuk/acme-tiny-docker.svg)](https://hub.docker.com/r/mdawsonuk/acme-tiny-docker "Click to view the image on hub.docker.com")
[![Docker pulls](https://img.shields.io/docker/pulls/mdawsonuk/acme-tiny-docker.svg)](https://hub.docker.com/r/mdawsonuk/acme-tiny-docker "Click to view the image on hub.docker.com")

This Docker container takes the work done by [diafgi's acme-tiny](https://github.com/diafygi/acme-tiny) and packages it up into Docker.

### Usage

Once DNS records have been updated to point to this server, the container can be run using the following command:

```console
docker run -d -p 80:80 -e COMMON_NAME=example.com -v ./config/example.com:/data mdawsonuk/acme-tiny-docker
```

This will start a Docker container listening on port 80 for the domain `example.com`. 

For a more advanced setup with multiple common names, the use of a proxy will be beneficial, such as the proxy included in the `docker-compose.yml` file.

### Environment variables

`COMMON_NAME`: The common name for this certificate.

`ALT_NAMES`: Semi-colon separated list of alternative DNS names for this certificate.

N.B: Alt names must be separated by a `;`. If used, jwilder/nginx-proxy must separate `VIRTUAL_HOST` domains with a `,`.

`KEY_TYPE`: The type of key to use for this certificate. Valid values are `RSA` and `ECDSA` (case-insensitive). Defaults to `RSA`.

`KEY_SIZE`: The size of the key. The valid values for this depend on the set value of `KEY_TYPE`. For `RSA`, the valid values are `2048`, `3072`, and `4096`. For `ECDSA`, the valid values are `256` and `384`. Defaults to `2048`. 

`STAGING`: Should acme-tiny use the Let's Encrypt Staging server. Valid values are `0` or `1`. Defaults to `0`.

`DISABLE_CHECK`: Should acme-tiny disable the Let's Encrypt check of the domain. Valid values are `0` or `1`. Defaults to `0`.

`DEBUG`: Increased verbosity in Docker log output. Valid values are `0` or `1`. Defaults to `0`.
