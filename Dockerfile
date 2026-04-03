# Use an official Ubuntu runtime as a parent image
FROM ubuntu:24.04@sha256:186072bba1b2f436cbb91ef2567abca677337cfc786c86e107d25b7072feef0c

#ENV SYNC_USERNAME
#ENV SYNC_PASSWORD

RUN apt-get update -y && \
    apt-get upgrade -y && \
    apt-get install -y curl cifs-utils inetutils-ping rsync && \
    rm -rf /var/lib/apt/lists/*


COPY run-sync.sh /usr/local/bin/run-sync
COPY update-staging-folders.sh /usr/local/bin/update-staging-folders

RUN chmod +x /usr/local/bin/run-sync /usr/local/bin/update-staging-folders


