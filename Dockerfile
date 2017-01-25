FROM jubicoy/jenkins-base-debian

USER root

# Extra deps
RUN dpkg --add-architecture i386
RUN apt-get update && apt-get install -y \
  build-essential \
  expect \
  lib32stdc++6 \
  maven \
  gcc-4.9-base:i386 \
  libgcc1:i386 \
  libc6:i386 \
  zlib1g:i386 \
  make \
  gettext \
  xvfb \
  ldap-utils

# from nodejs/docker-node
# gpg keys listed at https://github.com/nodejs/node
RUN set -ex \
  && for key in \
    9554F04D7259F04124DE6B476D5A82AC7E37093B \
    94AE36675C464D64BAFA68DD7434390BDBE9B9C5 \
    0034A06D9D9B0064CE8ADF6BF1747F4AD2306D93 \
    FD3A5288F042B6850C66B31F09FE44734EB7990E \
    71DCFD284A79C3B38668286BC97EC7A07EDE3FC1 \
    DD8F2338BAE7501E3DD5AC78C273792F7D83545D \
    B9AE9905FFD7803F25714661B63B535A4C206CA9 \
    C4F0DFFF4E8C1A8236409D08E73BC641CC11F4C8 \
  ; do \
    gpg --keyserver ha.pool.sks-keyservers.net --recv-keys "$key"; \
  done

ENV NPM_CONFIG_LOGLEVEL info
ENV NODE_VERSION 7.3.0

RUN curl -SLO "https://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION-linux-x64.tar.xz" \
  && curl -SLO "https://nodejs.org/dist/v$NODE_VERSION/SHASUMS256.txt.asc" \
  && gpg --batch --decrypt --output SHASUMS256.txt SHASUMS256.txt.asc \
  && grep " node-v$NODE_VERSION-linux-x64.tar.xz\$" SHASUMS256.txt | sha256sum -c - \
  && tar -xJf "node-v$NODE_VERSION-linux-x64.tar.xz" -C /usr/local --strip-components=1 \
  && rm "node-v$NODE_VERSION-linux-x64.tar.xz" SHASUMS256.txt.asc SHASUMS256.txt \
  && ln -s /usr/local/bin/node /usr/local/bin/nodejs

# install oc
ENV OPENSHIFT_VERSION v1.2.1
ENV OPENSHIFT_COMMIT_SHA 5e723f6
ENV OPENSHIFT_INSTALL_TMP /tmp/.jubicoy-openshift-tmp
RUN mkdir -p "${OPENSHIFT_INSTALL_TMP}/extracted" \
  && cd "${OPENSHIFT_INSTALL_TMP}" \
  && curl -SLO "https://github.com/openshift/origin/releases/download/${OPENSHIFT_VERSION}/openshift-origin-client-tools-${OPENSHIFT_VERSION}-${OPENSHIFT_COMMIT_SHA}-linux-64bit.tar.gz" \
  && tar -xzvf "openshift-origin-client-tools-${OPENSHIFT_VERSION}-${OPENSHIFT_COMMIT_SHA}-linux-64bit.tar.gz" -C "${OPENSHIFT_INSTALL_TMP}/extracted" --strip-components=1 \
  && cp "${OPENSHIFT_INSTALL_TMP}/extracted/oc" /usr/local/bin/ \
  && rm "openshift-origin-client-tools-${OPENSHIFT_VERSION}-${OPENSHIFT_COMMIT_SHA}-linux-64bit.tar.gz" "${OPENSHIFT_INSTALL_TMP}" -rf

# install firefox deps
RUN apt-get update && apt-get install -y iceweasel \
  && dpkg -P --force-all iceweasel
# install firefox
ENV FIREFOX_VERSION 47.0.1
ENV FIREFOX_SHA a56b2ad26df424f008d96968a4e6a10406694b33f42d962f19dff1a0bcdf261bca5dd0e5c6f3af32d892c3268da5ebee8ce182090f04f8480d37d232ccd23b9f
ENV FIREFOX_INSTALL_TMP /tmp/.jubicoy-firefox-tmp
RUN mkdir -p "${FIREFOX_INSTALL_TMP}/extracted" \
  && cd "${FIREFOX_INSTALL_TMP}" \
  && curl -SLO "https://releases.mozilla.org/pub/firefox/releases/${FIREFOX_VERSION}/linux-x86_64/en-US/firefox-${FIREFOX_VERSION}.tar.bz2" \
  && echo "${FIREFOX_SHA} firefox-${FIREFOX_VERSION}.tar.bz2"|sha512sum -c - \
  && tar -xjf "firefox-${FIREFOX_VERSION}.tar.bz2" -C "${FIREFOX_INSTALL_TMP}/extracted" \
  && mv "${FIREFOX_INSTALL_TMP}/extracted/firefox" /usr/local/firefox \
  && rm "firefox-${FIREFOX_VERSION}.tar.bz2" "${FIREFOX_INSTALL_TMP}" -rf \
  && ln -s /usr/local/firefox/firefox /usr/local/bin/firefox

# Enable Java 8
RUN apt-get install -y java-common \
  && update-java-alternatives -s java-1.8.0-openjdk-amd64

RUN rm -rf /var/lib/apt/lists/*

# Fix Xvfb /tmp/.X11-unix permissions
RUN mkdir -p /tmp/.X11-unix \
  && chmod 1777 /tmp/.X11-unix \
  && chown 0 /tmp/.X11-unix

ENV HOME /var/jenkins_home
USER 1000
