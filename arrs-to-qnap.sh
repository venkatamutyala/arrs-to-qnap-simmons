#!/bin/bash

set -e

# Define arrays for mount points and network shares
MOUNTS_ROOT="/mnt/qnap/"
MOUNTS=(
    "movies"
    "tvshows"
    "books"
    "music"
)

SHARES_ROOT="//plexd.randrservices.com/PlexData/"
SHARES=(
    "Movies"
    "TV Shows"
    "Books"
    "iTunes/iTunes Media"
)


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
for i in "${!MOUNTS[@]}"; do
    mount_if_needed "$SHARES_ROOT${SHARES[i]}" "$MOUNTS_ROOT${MOUNTS[i]}"
done


# Path to store the last run timestamp
LOG_FILE="log_run.txt"

while true; do
    # Current time in seconds since the epoch
    START_TIME=$(date '+%Y-%m-%d %H:%M:%S')

    # Record the current time as the last run time
    echo "START TIME: ${START_TIME}" >> "$LOG_FILE"
    echo "START TIME: ${START_TIME}"
    
    for i in "${!MOUNTS[@]}"; do
        echo "***** ${MOUNTS[i]} *****"
        mv "$MOUNTS_ROOT${MOUNTS[i]}"/* "$SHARES_ROOT${SHARES[i]}" || true
        find "$MOUNTS_ROOT${MOUNTS[i]} -mindepth 1 -type d -empty -delete" || true
    done

    FINISH_TIME=$(date '+%Y-%m-%d %H:%M:%S')
    echo "FINISH TIME: ${FINISH_TIME}" >> "$LOG_FILE"
    echo "FINISH TIME: ${FINISH_TIME}"

    # Sleep to avoid excessive CPU usage, then check again
    sleep 120
done
