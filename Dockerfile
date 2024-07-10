# Use an official Ubuntu runtime as a parent image
FROM ubuntu:24.04@sha256:2e863c44b718727c860746568e1d54afd13b2fa71b160f5cd9058fc436217b30

#ENV SYNC_USERNAME
#ENV SYNC_PASSWORD

RUN apt-get update -y && \
    apt-get upgrade -y && \
    apt-get install -y curl cifs-utils inetutils-ping rsync && \
    rm -rf /var/lib/apt/lists/*


COPY arrs-to-qnap.sh /usr/local/bin/arrs-to-qnap

RUN chmod +x /usr/local/bin/arrs-to-qnap

CMD ["arrs-to-qnap"]
