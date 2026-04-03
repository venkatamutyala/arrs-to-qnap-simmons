# Use an official Ubuntu runtime as a parent image
FROM ubuntu:24.04@sha256:186072bba1b2f436cbb91ef2567abca677337cfc786c86e107d25b7072feef0c

#ENV SYNC_USERNAME
#ENV SYNC_PASSWORD

RUN apt-get update -y && \
    apt-get upgrade -y && \
    apt-get install -y curl cifs-utils inetutils-ping rsync && \
    rm -rf /var/lib/apt/lists/*


COPY sync-from-staging.sh /usr/local/bin/run-sync
COPY staging-folders.sh /usr/local/bin/update-staging-folders
COPY sync-from-staging-windows.sh /usr/local/bin/run-sync-windows

RUN chmod +x /usr/local/bin/run-sync /usr/local/bin/update-staging-folders /usr/local/bin/run-sync-windows


