#!/bin/bash

set -e

# Define arrays for mount points and network shares
MOUNTS=(
    "/mnt/qnap/movies"
    "/mnt/qnap/tvshows"
    "/mnt/qnap/books"
    "/mnt/qnap/music"
)

SHARES=(
    "//plexd.randrservices.com/PlexData/Movies"
    "//plexd.randrservices.com/PlexData/TV Shows"
    "//plexd.randrservices.com/PlexData/Books"
    "//plexd.randrservices.com/PlexData/iTunes/iTunes Media"
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
    mount_if_needed "${SHARES[i]}" "${MOUNTS[i]}"
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
        ls -al "${MOUNTS[i]}"
    done

    FINISH_TIME=$(date '+%Y-%m-%d %H:%M:%S')
    # Sleep for ten minutes to avoid excessive CPU usage, then check again
    echo "FINISH TIME: ${FINISH_TIME}" >> "$LOG_FILE"
    echo "FINISH TIME: ${FINISH_TIME}"
    
    sleep 30
done
