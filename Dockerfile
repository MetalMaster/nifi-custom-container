FROM openjdk:8-jre
LABEL maintainer "Apache NiFi <dev@nifi.apache.org>"

ARG UID=1000
ARG GID=1000
ARG NIFI_VERSION=1.8.0
ARG MIRROR=https://archive.apache.org/dist

ENV NIFI_BASE_DIR /opt/nifi 
ENV NIFI_HOME=$NIFI_BASE_DIR/nifi-$NIFI_VERSION \
    NIFI_BINARY_URL=/nifi/$NIFI_VERSION/nifi-$NIFI_VERSION-bin.tar.gz \
    NIFI_DATA_DIR=/opt/data
ENV NIFI_PID_DIR=${NIFI_HOME}/run
ENV NIFI_LOG_DIR=${NIFI_HOME}/logs

ADD sh/ ${NIFI_BASE_DIR}/scripts/

# Setup NiFi user
RUN groupadd -g $GID nifi || groupmod -n nifi `getent group $GID | cut -d: -f1` \
    && useradd --shell /bin/bash -u $UID -g $GID -m nifi \
    && mkdir -p $NIFI_HOME/conf/templates \
    && chown -R nifi:nifi $NIFI_BASE_DIR
    
#Create data dirs
RUN mkdir -p ${NIFI_HOME}/data/templates \
	&& mkdir -p ${NIFI_HOME}/database_repository \
	&& mkdir -p ${NIFI_HOME}/flowfile_repository \
	&& mkdir -p ${NIFI_HOME}/content_repository \
	&& mkdir -p ${NIFI_HOME}/provenance_repository \
	&& mkdir -p ${NIFI_LOG_DIR} \
	&& chown -R nifi:nifi ${NIFI_HOME}

RUN mkdir -p ${NIFI_DATA_DIR} \
    && chown -R nifi:nifi ${NIFI_DATA_DIR}

USER nifi

# Download, validate, and expand Apache NiFi binary.
RUN curl -fSL $MIRROR/$NIFI_BINARY_URL -o $NIFI_BASE_DIR/nifi-$NIFI_VERSION-bin.tar.gz \
    && echo "$(curl https://archive.apache.org/dist/$NIFI_BINARY_URL.sha256) *$NIFI_BASE_DIR/nifi-$NIFI_VERSION-bin.tar.gz" | sha256sum -c - \
    && tar -xvzf $NIFI_BASE_DIR/nifi-$NIFI_VERSION-bin.tar.gz -C $NIFI_BASE_DIR \
    && rm $NIFI_BASE_DIR/nifi-$NIFI_VERSION-bin.tar.gz \
    && chown -R nifi:nifi $NIFI_HOME

COPY lib/* ${NIFI_HOME}/lib/

#COPY conf/* ${NIFI_HOME}/conf/

# Clear nifi-env.sh in favour of configuring all environment variables in the Dockerfile
RUN echo "#!/bin/sh\n" > $NIFI_HOME/bin/nifi-env.sh

#RUN chown -R nifi:nifi ${NIFI_HOME}/lib/*


# Web HTTP Port & Remote Site-to-Site Ports
EXPOSE 8080 8181 8443 10000

WORKDIR $NIFI_HOME

# Startup NiFi
#ENTRYPOINT ["bin/nifi.sh"]
#CMD ["run"]

# Apply configuration and start NiFi
#
# We need to use the exec form to avoid running our command in a subshell and omitting signals,
# thus being unable to shut down gracefully:
# https://docs.docker.com/engine/reference/builder/#entrypoint
#
# Also we need to use relative path, because the exec form does not invoke a command shell,
# thus normal shell processing does not happen:
# https://docs.docker.com/engine/reference/builder/#exec-form-entrypoint-example
ENTRYPOINT ["../scripts/start.sh"]
