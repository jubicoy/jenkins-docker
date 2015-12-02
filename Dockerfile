FROM jubicoy/jenkins-base

USER root

# Group Development Tools
RUN yum install -y \
  bison \
  byacc \
  cscope \
  ctags \
  cvs \
  diffstat \
  doxygen \
  flex \
  gcc \
  gcc-c++ \
  gcc-gfortran \
  git \
  indent \
  intltool \
  libtool \
  patch \
  patchutils \
  rcs \
  subversion \
  swig \
  systemtap

# Extra deps
RUN  yum install -y \
  kernel-devel \
  expect \
  libstdc++.i686 \
  zlib.i686 \
  zlib-devel.i686 \
  maven \
  make \
  gettext \
  xorg-x11-server-Xvfb \
  curl \
  wget \
  bzip2

# from nodejs/docker-node
ENV NODE_VERSION 0.10.40
ENV NPM_VERSION 2.14.1

RUN set -ex \
  && for key in \
    7937DFD2AB06298B2293C3187D33FF9D0246406D \
    114F43EE0176B71C7BC219DD50A3051F888C628D \
  ; do \
    gpg --homedir  /var/lib/jenkins/.gnupg --keyserver ha.pool.sks-keyservers.net --recv-keys "$key"; \
  done \
  && curl -SLO "https://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION-linux-x64.tar.gz" \
  && curl -SLO "https://nodejs.org/dist/v$NODE_VERSION/SHASUMS256.txt.asc" \
  && gpg --homedir /var/lib/jenkins/.gnupg --verify SHASUMS256.txt.asc \
  && grep " node-v$NODE_VERSION-linux-x64.tar.gz\$" SHASUMS256.txt.asc | sha256sum -c - \
  && tar -xzf "node-v$NODE_VERSION-linux-x64.tar.gz" -C /usr/local --strip-components=1 \
  && rm "node-v$NODE_VERSION-linux-x64.tar.gz" SHASUMS256.txt.asc \
  && npm install -g npm@"$NPM_VERSION" \
  && npm cache clear

# Setup DBus
RUN dbus-uuidgen > /etc/machine-id

# install firefox
RUN yum install -y firefox \
  && rpm -e --nodeps firefox
RUN mkdir -p /tmp/.jubicoy-firefox-tmp \
  && cd /tmp/.jubicoy-firefox-tmp \
  && curl -SLO "https://download-installer.cdn.mozilla.net/pub/firefox/releases/41.0.2/linux-x86_64/en-US/firefox-41.0.2.tar.bz2" \
  && ls -alh \
  && mkdir -p ext-tgt \
  && tar -xjf /tmp/.jubicoy-firefox-tmp/firefox-41.0.2.tar.bz2 -C /tmp/.jubicoy-firefox-tmp/ext-tgt \
  && mv /tmp/.jubicoy-firefox-tmp/ext-tgt/firefox /usr/local/firefox \
  && rm /tmp/.jubicoy-firefox-tmp -rf \
  && ln -s /usr/local/firefox/firefox /usr/local/bin/firefox

RUN yum -y clean all

# Enable Java 8
RUN alternatives --set java /usr/lib/jvm/java-1.8.0-openjdk-1.8.0.65-2.b17.el7_1.x86_64/jre/bin/java \
  && alternatives --set javac /usr/lib/jvm/java-1.8.0-openjdk-1.8.0.65-2.b17.el7_1.x86_64/bin/javac

USER 1001
