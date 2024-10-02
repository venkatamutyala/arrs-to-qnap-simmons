# Use an official Ubuntu runtime as a parent image
FROM ubuntu:20.04@sha256:6d8d9799fe6ab3221965efac00b4c34a2bcc102c086a58dff9e19a08b913c7ef

#ENV SYNC_USERNAME
#ENV SYNC_PASSWORD

RUN apt-get update -y && \
    apt-get upgrade -y && \
    apt-get install -y curl cifs-utils inetutils-ping rsync && \
    rm -rf /var/lib/apt/lists/*


COPY arrs-to-qnap.sh /usr/local/bin/arrs-to-qnap

RUN chmod +x /usr/local/bin/arrs-to-qnap

CMD ["arrs-to-qnap"]
