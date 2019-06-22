FROM apache/nifi:1.9.2
LABEL custom apache/nifi

COPY lib/* ${NIFI_HOME}/lib/

EXPOSE 8080


