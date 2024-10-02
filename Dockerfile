# Use an official Ubuntu runtime as a parent image
FROM ubuntu:24.04@sha256:b359f1067efa76f37863778f7b6d0e8d911e3ee8efa807ad01fbf5dc1ef9006b

#ENV SYNC_USERNAME
#ENV SYNC_PASSWORD

RUN apt-get update -y && \
    apt-get upgrade -y && \
    apt-get install -y curl cifs-utils inetutils-ping rsync && \
    rm -rf /var/lib/apt/lists/*


COPY arrs-to-qnap.sh /usr/local/bin/arrs-to-qnap

RUN chmod +x /usr/local/bin/arrs-to-qnap

CMD ["arrs-to-qnap"]
