# Use an official Ubuntu runtime as a parent image
FROM ubuntu:20.04@sha256:0b897358ff6624825fb50d20ffb605ab0eaea77ced0adb8c6a4b756513dec6fc

#ENV SYNC_USERNAME
#ENV SYNC_PASSWORD

RUN apt-get update -y && \
    apt-get upgrade -y && \
    apt-get install -y curl cifs-utils inetutils-ping rsync && \
    rm -rf /var/lib/apt/lists/*


COPY arrs-to-plex26.sh /usr/local/bin/arrs-to-plex26

RUN chmod +x /usr/local/bin/arrs-to-plex26

CMD ["arrs-to-plex26"]

