ARG VARIANT=jammy
FROM mcr.microsoft.com/vscode/devcontainers/base:${VARIANT}

LABEL Description="Dockerized MiKTeX, Ubuntu 22.04"
LABEL Vendor="Christian Schenk"
LABEL Version="23.10.5"

ARG DEBIAN_FRONTEND=noninteractive

ARG user=miktex
ARG group=miktex
ARG uid=1000
ARG gid=1000

ARG miktex_home=/var/lib/miktex
ARG miktex_work=/miktex/work

RUN groups vscode

RUN groupmod -g ${gid} -n ${group} vscode \
    && usermod -d "${miktex_home}" -u ${uid} -g ${gid} -m -s /bin/bash -l ${user} vscode

RUN    apt-get update \
    && apt-get install -y --no-install-recommends \
           apt-transport-https \
           ca-certificates \
           curl \
           dirmngr \
           ghostscript \
           gnupg \
           gosu \
           perl

RUN apt-get update && \ 
  # basic utilities for TeX Live installation
  apt-get install -y wget rsync unzip git gpg tar xorriso \ 
  # miscellaneous dependencies for TeX Live tools
  make fontconfig perl default-jre libgetopt-long-descriptive-perl \
  libdigest-perl-md5-perl libncurses5 libncurses6 \
  # for latexindent (see #13)
  libunicode-linebreak-perl libfile-homedir-perl libyaml-tiny-perl \
  # for eps conversion (see #14)
  ghostscript \
  # for l3build CTAN upload
  curl \
  # for syntax highlighting
  python3 python3-pygments && \ 
  rm -rf /var/lib/apt/lists/* && \
  rm -rf /var/cache/apt/ && \ 
  # bad fix for python handling
  ln -s /usr/bin/python3 /usr/bin/python
  
RUN apt-get update && apt-get install -y inkscape

RUN curl -fsSL https://miktex.org/download/key | tee /usr/share/keyrings/miktex-keyring.asc > /dev/null \
    && echo "deb [signed-by=/usr/share/keyrings/miktex-keyring.asc] https://miktex.org/download/ubuntu jammy universe" | tee /etc/apt/sources.list.d/miktex.list

RUN    apt-get update -y \
    && apt-get install -y --no-install-recommends \
           miktex

USER ${user}

RUN    miktexsetup finish \
    && initexmf --set-config-value=[MPM]AutoInstall=1 \
    && miktex packages update \
    && miktex packages install amsfonts

VOLUME [ "${miktex_home}" ]

WORKDIR ${miktex_work}

USER root
    
COPY entrypoint.sh /
ENTRYPOINT ["/entrypoint.sh"]

ENV PATH=/var/lib/miktex/bin:${PATH}

CMD ["sleep", "infinity"]
