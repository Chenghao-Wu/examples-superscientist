# syntax=docker/dockerfile:1.7
# Reproducible LAMMPS environment for superscientist demos.
# The lockfile is the source of truth — regenerate via the README instructions
# if you bump environment.yml.

FROM mambaorg/micromamba:2.0-ubuntu24.04

COPY conda-linux-64.lock /tmp/lock

USER root
RUN micromamba install -y -n base --file /tmp/lock && \
    micromamba clean --all --yes && \
    rm /tmp/lock

USER mambauser
WORKDIR /work

# Inherit /usr/local/bin/_entrypoint.sh from the base image — it activates the
# conda env before exec'ing the CMD. Default CMD is bash so `docker run -it`
# without args drops the user into a shell with the env active.
CMD ["bash"]
