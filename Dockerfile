FROM debian:jessie

MAINTAINER Stanislav Khotinok <stanislav.khotinok@gmail.com>

RUN apt-get update && apt-get install -y \
  apache2-utils \
  bash \
  ca-certificates \
  curl \
  nginx \
  supervisor \
  tar \
&& apt-get clean all && rm -rf /var/lib/apt/lists/*

RUN rm /etc/nginx/sites-enabled/default
COPY ./conf/nginx/nginx.conf /etc/nginx/nginx.conf

RUN mkdir -p /var/log/supervisor

# forward request and error logs to docker log collector
RUN ln -sf /dev/stdout /var/log/nginx/access.log \
  && ln -sf /dev/stderr /var/log/nginx/error.log

# configure java runtime
ENV JAVA_HOME=/opt/java \
  JAVA_VERSION_MAJOR=8 \
  JAVA_VERSION_MINOR=144 \
  JAVA_VERSION_BUILD=01 \
  JAVA_VERSION_URL_HASH=090f390dda5b47b9b721c7dfaa008135 \
  JAVA_VERSION_SHA256=8ba6f1c692518beb0c727c6e1fb8c30a5dfcc38f8ef9f4f7c7c114c01c747ebc

ENV JAVA_DOWNLOAD_URL=http://download.oracle.com/otn-pub/java/jdk/${JAVA_VERSION_MAJOR}u${JAVA_VERSION_MINOR}-b${JAVA_VERSION_BUILD}/${JAVA_VERSION_URL_HASH}/server-jre-${JAVA_VERSION_MAJOR}u${JAVA_VERSION_MINOR}-linux-x64.tar.gz

# install oracle jre
RUN mkdir -p /opt \
  && curl --fail --silent --location --retry 3 \
  --header "Cookie: oraclelicense=accept-securebackup-cookie; " \
  ${JAVA_DOWNLOAD_URL} \
  | gunzip \
  | tar -x -C /opt \
  &&  ln -s /opt/jdk1.${JAVA_VERSION_MAJOR}.0_${JAVA_VERSION_MINOR} ${JAVA_HOME}

# check installation of the oracle jre
RUN ${JAVA_HOME}/bin/java -version

# nexus
ARG NEXUS_VERSION=3.6.0-02
ARG NEXUS_DOWNLOAD_URL=https://download.sonatype.com/nexus/3/nexus-${NEXUS_VERSION}-unix.tar.gz
ARG NEXUS_SHA1_URL=https://download.sonatype.com/nexus/3/nexus-${NEXUS_VERSION}-unix.tar.gz.sha1

# configure nexus runtime
ENV SONATYPE_DIR=/opt/sonatype
ENV NEXUS_HOME=${SONATYPE_DIR}/nexus \
  NEXUS_DATA=/nexus-data \
  NEXUS_CONTEXT='' \
  SONATYPE_WORK=${SONATYPE_DIR}/sonatype-work

# install nexus
RUN mkdir -p ${NEXUS_HOME} \
  && curl --fail --silent --location --retry 3 \
  ${NEXUS_DOWNLOAD_URL} \
  | gunzip \
  | tar x -C ${NEXUS_HOME} --strip-components=1 nexus-${NEXUS_VERSION} \
  && chown -R root:root ${NEXUS_HOME}

# configure nexus
RUN sed \
  -e '/^nexus-context/ s:$:${NEXUS_CONTEXT}:' \
  -i ${NEXUS_HOME}/etc/nexus-default.properties

RUN useradd -r -u 200 -m -c "nexus role account" -d ${NEXUS_DATA} -s /bin/false nexus \
  && mkdir -p ${NEXUS_DATA}/etc ${NEXUS_DATA}/log ${NEXUS_DATA}/tmp ${SONATYPE_WORK} \
  && ln -s ${NEXUS_DATA} ${SONATYPE_WORK}/nexus3 \
  && chown -R nexus:nexus ${NEXUS_DATA}

VOLUME ${NEXUS_DATA}
VOLUME ["/certs", "/etc/nginx/conf.d", "/var/log/nginx", "/var/log/supervisor"]

EXPOSE 443
USER nexus
WORKDIR ${NEXUS_HOME}

ENV JAVA_MAX_MEM=1200m \
  JAVA_MIN_MEM=1200m \
  EXTRA_JAVA_OPTS=""

COPY ./conf/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

USER root

COPY ./docker-entrypoint.sh /usr/local/bin/
RUN ln -s /usr/local/bin/docker-entrypoint.sh / # backwards compatibility
RUN ls -al /
RUN pwd
RUN chmod +x /usr/local/bin/docker-entrypoint.sh
ENTRYPOINT ["docker-entrypoint.sh"]
