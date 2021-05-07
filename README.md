# docker-overleaf-ldap

[![pipeline status](https://git.stuvus.uni-stuttgart.de/ref-it/docker-overleaf-ldap/badges/main/pipeline.svg)](https://git.stuvus.uni-stuttgart.de/ref-it/docker-overleaf-ldap/-/pipelines?ref=main)

This repository provides an OCI image for
[Overleaf](https://github.com/overleaf/overleaf) bundled with
[ldap-overleaf-sl](https://github.com/smhaller/ldap-overleaf-sl)
to support LDAP authentication.
One can use [Docker](https://www.docker.com/) in order to build the image,
as follows.

```sh
docker build --build-arg BASE=docker.io/sharelatex/sharelatex:2.6.1 -t docker-overleaf-ldap .
```

## Environment variables

Two environment variables are used at runtime to configure the bind user:

- `LDAP_BIND_USER`: Bind-DN, i.e., DN of the bind user.
- `LDAP_BIND_PW`: Password of the bind user.

## Build arguments

The following arguments can be passed via `--build-args`.

| Argument          | Default                                                               | Description                                                                                                                                            |
| ----------------- | --------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `BASE`            | `docker.io/sharelatex/sharelatex`                                     | Can be set to any Overleaf image tag. See [here](https://hub.docker.com/r/sharelatex/sharelatex/tags?page=1&ordering=last_updated) for a list of tags. |
| `LDAP_PLUGIN_URL` | `https://codeload.github.com/smhaller/ldap-overleaf-sl/tar.gz/master` | URL to download ldap-overleaf-sl from.                                                                                                                 |

## GitLab CI

The `environment` file is used to specify some environment variables for the GitLab CI:

* `BASE`: Gets passed to the `BASE` build argument.
* `LDAP_PLUGIN_URL`: Gets passed to the `LDAP_PLUGIN_URL` build argument.
* `IMAGE_TAG`: Is used as image tag, but only in the build for the branch `main`.
