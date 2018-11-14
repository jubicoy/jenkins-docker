FROM jubicoy/jenkins-base-debian

USER root

# Extra deps
RUN dpkg --add-architecture i386
RUN apt-get update && apt-get install -y \
    apt-transport-https \
    build-essential \
    chromium \
    chromedriver \
    expect \
    gettext \
    jq \
    make \
    maven \
    ldap-utils \
    lib32stdc++6 \
    libgcc1:i386 \
    libc6:i386 \
    libxml-xpath-perl \
    zlib1g:i386 \
  && rm -rf /var/lib/apt/lists/*

# Add dotnet repository
# https://www.microsoft.com/net/learn/get-started-with-dotnet-tutorial#linuxdebian
RUN wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --batch --dearmor > microsoft.asc.gpg \
  && mv microsoft.asc.gpg /etc/apt/trusted.gpg.d/ \
  && wget -q https://packages.microsoft.com/config/debian/9/prod.list \
  && mv prod.list /etc/apt/sources.list.d/microsoft-prod.list \
  && apt-get update \
  && apt-get install -y dotnet-sdk-2.1 \
  && rm -rf /var/lib/apt/lists/*

# from nodejs/docker-node
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
    8FCCA13FEF1D0C2E91008E09770F7A9A5AE15600 \
  ; do \
    gpg --batch --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys "$key" || \
    gpg --batch --keyserver hkp://ipv4.pool.sks-keyservers.net --recv-keys "$key" || \
    gpg --batch --keyserver hkp://pgp.mit.edu:80 --recv-keys "$key" ; \
  done

ENV NODE_VERSION 8.11.4

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

ENV YARN_VERSION 1.9.2

RUN set -ex \
  && for key in \
    6A010C5166006599AA17F08146C2130DFD2497F5 \
  ; do \
    gpg --batch --keyserver pgp.mit.edu --recv-keys "$key" || \
    gpg --batch --keyserver keyserver.pgp.com --recv-keys "$key" || \
    gpg --batch --keyserver ha.pool.sks-keyservers.net --recv-keys "$key" ; \
  done \
  && curl -fSLO --compressed "https://yarnpkg.com/downloads/$YARN_VERSION/yarn-v$YARN_VERSION.tar.gz" \
  && curl -fSLO --compressed "https://yarnpkg.com/downloads/$YARN_VERSION/yarn-v$YARN_VERSION.tar.gz.asc" \
  && gpg --batch --verify yarn-v$YARN_VERSION.tar.gz.asc yarn-v$YARN_VERSION.tar.gz \
  && mkdir -p /opt/yarn \
  && tar -xzf yarn-v$YARN_VERSION.tar.gz -C /opt/yarn --strip-components=1 \
  && ln -s /opt/yarn/bin/yarn /usr/local/bin/yarn \
  && ln -s /opt/yarn/bin/yarn /usr/local/bin/yarnpkg \
  && rm yarn-v$YARN_VERSION.tar.gz.asc yarn-v$YARN_VERSION.tar.gz

# install oc
ENV OPENSHIFT_VERSION v1.4.1
ENV OPENSHIFT_COMMIT_SHA 3f9807a
ENV OPENSHIFT_INSTALL_TMP /tmp/.jubicoy-openshift-tmp
RUN mkdir -p "${OPENSHIFT_INSTALL_TMP}/extracted" \
  && cd "${OPENSHIFT_INSTALL_TMP}" \
  && curl -SLO "https://github.com/openshift/origin/releases/download/${OPENSHIFT_VERSION}/openshift-origin-client-tools-${OPENSHIFT_VERSION}-${OPENSHIFT_COMMIT_SHA}-linux-64bit.tar.gz" \
  && tar -xzvf "openshift-origin-client-tools-${OPENSHIFT_VERSION}-${OPENSHIFT_COMMIT_SHA}-linux-64bit.tar.gz" -C "${OPENSHIFT_INSTALL_TMP}/extracted" --strip-components=1 \
  && cp "${OPENSHIFT_INSTALL_TMP}/extracted/oc" /usr/local/bin/ \
  && rm "openshift-origin-client-tools-${OPENSHIFT_VERSION}-${OPENSHIFT_COMMIT_SHA}-linux-64bit.tar.gz" "${OPENSHIFT_INSTALL_TMP}" -rf

# Enable Java 8
RUN apt-get install -y java-common \
  && update-java-alternatives -s java-1.8.0-openjdk-amd64 \
  && rm -rf /var/lib/apt/lists/*

ENV HOME /var/jenkins_home
USER 1000
