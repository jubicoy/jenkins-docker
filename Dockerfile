FROM jubicoy/jenkins-base-debian

USER root

# Extra deps
RUN dpkg --add-architecture i386
RUN apt-get update && apt-get install -y \
  build-essential \
  expect \
  lib32stdc++6 \
  maven \
  zlib1g:i386 \
  make \
  gettext \
  xvfb

# from nodejs/docker-node
ENV NODE_VERSION 0.10.40
ENV NPM_VERSION 2.14.1
RUN set -ex \
    && for key in \
      7937DFD2AB06298B2293C3187D33FF9D0246406D \
      114F43EE0176B71C7BC219DD50A3051F888C628D \
    ; do \
      gpg --keyserver ha.pool.sks-keyservers.net --recv-keys "$key"; \
    done \
  && curl -SLO "https://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION-linux-x64.tar.gz" \
  && curl -SLO "https://nodejs.org/dist/v$NODE_VERSION/SHASUMS256.txt.asc" \
  && gpg --verify SHASUMS256.txt.asc \
  && grep " node-v$NODE_VERSION-linux-x64.tar.gz\$" SHASUMS256.txt.asc | sha256sum -c - \
  && tar -xzf "node-v$NODE_VERSION-linux-x64.tar.gz" -C /usr/local --strip-components=1 \
  && rm "node-v$NODE_VERSION-linux-x64.tar.gz" SHASUMS256.txt.asc \
  && npm install -g npm@"$NPM_VERSION" \
  && npm cache clear

# install oc
ENV OPENSHIFT_VERSION v1.1
ENV OPENSHIFT_COMMIT_SHA ac7a99a
ENV OPENSHIFT_INSTALL_TMP /tmp/.jubicoy-openshift-tmp
RUN mkdir -p "${OPENSHIFT_INSTALL_TMP}/extracted" \
  && cd "${OPENSHIFT_INSTALL_TMP}" \
  && curl -SLO "https://github.com/openshift/origin/releases/download/${OPENSHIFT_VERSION}/openshift-origin-${OPENSHIFT_VERSION}-${OPENSHIFT_COMMIT_SHA}-linux-amd64.tar.gz" \
  && tar -xzvf "openshift-origin-${OPENSHIFT_VERSION}-${OPENSHIFT_COMMIT_SHA}-linux-amd64.tar.gz" -C "${OPENSHIFT_INSTALL_TMP}/extracted" --strip-components=1 \
  && cp "${OPENSHIFT_INSTALL_TMP}/extracted/oc" /usr/local/bin/ \
  && rm "openshift-origin-${OPENSHIFT_VERSION}-${OPENSHIFT_COMMIT_SHA}-linux-amd64.tar.gz" "${OPENSHIFT_INSTALL_TMP}" -rf

# install firefox deps
RUN apt-get update && apt-get install -y iceweasel \
  && dpkg -P --force-all iceweasel
# install firefox
ENV FIREFOX_VERSION 42.0
ENV FIREFOX_SHA 717e95a8db926d000edb5220b9d63344a4de4cc3d6af2e374d2a39eaf1e873066d7d1b1cef3fa2c744d7587b548035aeefbcaef41478a09012aa3581605d17ec
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
