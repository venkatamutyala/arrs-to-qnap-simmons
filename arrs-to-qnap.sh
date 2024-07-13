#!/bin/bash

set -e

# Define arrays for mount points and network shares
QNAP_SHARES="//plexd.randrservices.com/PlexData"

QNAP_MOUNTS="/mnt/qnap"

QNAP_FOLDERS=(
    "Movies"
    "TV Shows"
    "Books"
    "iTunes/iTunes Media"
)

ARRS_LOCATION="/srv/media/"

ARRS_FOLDERS=(
    "movies"
    "tvshows"
    "books"
    "music"
)

# Define Trigger file name if there was a file/folder to copy
TRIGGER_FILE="TRIGGERCOPY.TXT"

# Function to check and mount if not already mounted using findmnt
mount_if_needed() {
    local share=$1
    local mountpoint=$2

    # Ensure the mount point directory exists
    if [ ! -d "$mountpoint" ]; then
        echo "Creating mount point $mountpoint"
        mkdir -p "$mountpoint"
    fi

    # Use findmnt to check if the mount point is already used
    if findmnt -rno TARGET "$mountpoint" > /dev/null; then
        echo "$mountpoint is already mounted."
    else
        echo "Attempting to mount $share to $mountpoint"
        mount.cifs "$share" "$mountpoint" -o user=$SYNC_USERNAME,password=$SYNC_PASSWORD,vers=2.1
        if [ $? -ne 0 ]; then
            echo "Failed to mount $share on $mountpoint"
            dmesg | tail -10  # Display the last 10 kernel log messages to help diagnose the issue
        fi
    fi
}

# Mount the shares to the specified mount points
mount_if_needed "$QNAP_SHARES" "$QNAP_MOUNTS"

df -h

# Path to store the last run timestamp
LOG_FILE="log_run.txt"

while true; do
    # Current time in seconds since the epoch
    START_TIME=$(date '+%Y-%m-%d %H:%M:%S')

    # Record the current time as the last run time
    echo -n "START: ${START_TIME} " >> "$LOG_FILE"
    echo -n "START: ${START_TIME} "
    
    for i in "${!ARRS_FOLDERS[@]}"; do

        # check for files in the folder before doing any steps
        if [ -n "$(ls -A $ARRS_LOCATION${ARRS_FOLDERS[i]} 2>/dev/null)" ]
        then
            echo
            echo "*************** $ARRS_LOCATION${ARRS_FOLDERS[i]} to $QNAP_MOUNTS/${QNAP_FOLDERS[i]} ***************"
            # show the files and folders we will copy
            ls "$ARRS_LOCATION${ARRS_FOLDERS[i]}" || true
            # rsync the files and folders
            rsync -r -ah --remove-source-files -P "$ARRS_LOCATION${ARRS_FOLDERS[i]}"/ "$QNAP_MOUNTS/${QNAP_FOLDERS[i]}" || true
            # erase the folders and files if left over
            find "$ARRS_LOCATION${ARRS_FOLDERS[i]}" -mindepth 1 -type d -empty -delete || true
            # create trigger file to say we did a copy
            echo "${START_TIME}">"$QNAP_MOUNTS/${QNAP_FOLDERS[i]}/$TRIGGER_FILE"
            echo "*************** $ARRS_LOCATION${ARRS_FOLDERS[i]} to $QNAP_MOUNTS/${QNAP_FOLDERS[i]} Done ***************"
        else
            echo -n " No files $ARRS_LOCATION${ARRS_FOLDERS[i]} "
        fi
    done

    FINISH_TIME=$(date '+%Y-%m-%d %H:%M:%S')
    echo " FINISH: ${FINISH_TIME}" >> "$LOG_FILE"
    echo " FINISH: ${FINISH_TIME} "

    # Sleep to avoid excessive CPU usage, then check again
    sleep 120
done
