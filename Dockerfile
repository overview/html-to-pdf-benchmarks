FROM debian:stretch-slim

RUN sed -i -e 's/stretch main/stretch main contrib/' /etc/apt/sources.list && apt-get update && apt-get install -y \
      ca-certificates \
      curl \
      bzip2 \
      chromium \
      chromium-shell \
      libgtk-3-0 \
      libdbus-glib-1-2 \
      gpg \
      xz-utils \
      ttf-mscorefonts-installer \
      fonts-ipafont-mincho \
      fonts-ipafont-gothic \
      fonts-arphic-ukai \
      fonts-arphic-uming \
      fonts-nanum \
      poppler-utils \
      psmisc

# Detour: install NodeJS. (We need Debian Stretch for its browser versions. As
# of 2018-04-17, node:9.11.1-slim is built on Jessie and has old browsers.)
# Copied from https://github.com/nodejs/docker-node/blob/9023f588717d236a92d91a8483ff0582484c22d1/9/Dockerfile:

# gpg keys listed at https://github.com/nodejs/node#release-team
RUN set -ex \
  && for key in \
    94AE36675C464D64BAFA68DD7434390BDBE9B9C5 \
    FD3A5288F042B6850C66B31F09FE44734EB7990E \
    71DCFD284A79C3B38668286BC97EC7A07EDE3FC1 \
    DD8F2338BAE7501E3DD5AC78C273792F7D83545D \
    C4F0DFFF4E8C1A8236409D08E73BC641CC11F4C8 \
    B9AE9905FFD7803F25714661B63B535A4C206CA9 \
    56730D5401028683275BD23C23EFEFE93C4CFFFE \
    77984A986EBC2AA786BC0F66B01FBB92821C587A \
  ; do \
    gpg --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys "$key" || \
    gpg --keyserver hkp://ipv4.pool.sks-keyservers.net --recv-keys "$key" || \
    gpg --keyserver hkp://pgp.mit.edu:80 --recv-keys "$key" ; \
  done

ENV NODE_VERSION 9.11.1

RUN ARCH= && dpkgArch="$(dpkg --print-architecture)" \
  && case "${dpkgArch##*-}" in \
    amd64) ARCH='x64';; \
    ppc64el) ARCH='ppc64le';; \
    s390x) ARCH='s390x';; \
    arm64) ARCH='arm64';; \
    armhf) ARCH='armv7l';; \
    i386) ARCH='x86';; \
    *) echo "unsupported architecture"; exit 1 ;; \
  esac \
  && curl -SLO "https://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION-linux-$ARCH.tar.xz" \
  && curl -SLO --compressed "https://nodejs.org/dist/v$NODE_VERSION/SHASUMS256.txt.asc" \
  && gpg --batch --decrypt --output SHASUMS256.txt SHASUMS256.txt.asc \
  && grep " node-v$NODE_VERSION-linux-$ARCH.tar.xz\$" SHASUMS256.txt | sha256sum -c - \
  && tar -xJf "node-v$NODE_VERSION-linux-$ARCH.tar.xz" -C /usr/local --strip-components=1 --no-same-owner \
  && rm "node-v$NODE_VERSION-linux-$ARCH.tar.xz" SHASUMS256.txt.asc SHASUMS256.txt \
  && ln -s /usr/local/bin/node /usr/local/bin/nodejs

# </detour>

# Install Firefox. (Debian provides firefox-esr, which is too old for SlimerJS.)
RUN curl -o - --location https://download-installer.cdn.mozilla.net/pub/firefox/releases/60.0.1/linux-x86_64/en-US/firefox-60.0.1.tar.bz2 \
        | tar -xj -C / \
   && mkdir -p /opt \
   && mv /firefox /opt/

# Install SlimerJS
RUN curl -o - --location https://github.com/adamhooper/slimerjs/releases/download/stripped-to-the-minimum.001/slimerjs-1.1.0-pre.tar.bz2 \
        | tar -xj -C / \
    && mkdir -p /opt \
    && mv /slimerjs-1.* /opt/slimerjs

ENV PATH /opt/firefox:/opt/slimerjs:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin

# Install benchmark app
COPY using-chromium/ /app/using-chromium/
COPY using-slimerjs/ /app/using-slimerjs/
COPY benchmark /app/benchmark
COPY large.html medium.html small.html /app/
WORKDIR /app

CMD [ "/app/benchmark" ]
