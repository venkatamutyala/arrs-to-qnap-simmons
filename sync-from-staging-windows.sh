#!/bin/bash

set -e

# Parse CLI flags
usage() {
    echo "Usage: $0 --network-share <share> --network-mount <mountpoint> --arrs-location <path>"
    echo "  --network-share   The network share path (e.g., //server/share)"
    echo "  --network-mount   The local mount point (e.g., /mnt/qnap)"
    echo "  --arrs-location   The local arrs media path (e.g., /srv/media/)"
    exit 1
}

NETWORK_SHARE=""
NETWORK_MOUNT=""
ARRS_LOCATION=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --network-share)
            NETWORK_SHARE="$2"
            shift 2
            ;;
        --network-mount)
            NETWORK_MOUNT="$2"
            shift 2
            ;;
        --arrs-location)
            ARRS_LOCATION="$2"
            shift 2
            ;;
        *)
            echo "Error: Unknown option: $1"
            usage
            ;;
    esac
done

if [[ -z "$NETWORK_SHARE" ]]; then
    echo "Error: --network-share is required"
    usage
fi

if [[ -z "$NETWORK_MOUNT" ]]; then
    echo "Error: --network-mount is required"
    usage
fi

if [[ -z "$ARRS_LOCATION" ]]; then
    echo "Error: --arrs-location is required"
    usage
fi

NETWORK_FOLDERS=(
    "Movies"
    "TV Shows"
)

ARRS_FOLDERS=(
    "movies"
    "tvshows"
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
        mount.cifs "$share" "$mountpoint" -o user=$SYNC_USERNAME,password=$SYNC_PASSWORD,vers=3.0,sec=ntlmssp${SYNC_DOMAIN:+,domain=$SYNC_DOMAIN}
        if [ $? -ne 0 ]; then
            echo "Failed to mount $share on $mountpoint"
            dmesg | tail -10  # Display the last 10 kernel log messages to help diagnose the issue
        fi
    fi
}

# Mount the shares to the specified mount points
mount_if_needed "$NETWORK_SHARE" "$NETWORK_MOUNT"

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
            echo "*************** $ARRS_LOCATION${ARRS_FOLDERS[i]} to $NETWORK_MOUNT/${NETWORK_FOLDERS[i]} ***************"
            # show the files and folders we will copy
            ls "$ARRS_LOCATION${ARRS_FOLDERS[i]}" || true
            # rsync the files and folders
            rsync -r -ah --remove-source-files -P "$ARRS_LOCATION${ARRS_FOLDERS[i]}"/ "$NETWORK_MOUNT/${NETWORK_FOLDERS[i]}" || true
            # erase the folders and files if left over
            find "$ARRS_LOCATION${ARRS_FOLDERS[i]}" -mindepth 1 -type d -empty -delete || true
            # create trigger file to say we did a copy
            echo "${START_TIME}">"$NETWORK_MOUNT/${NETWORK_FOLDERS[i]}/$TRIGGER_FILE"
            echo "*************** $ARRS_LOCATION${ARRS_FOLDERS[i]} to $NETWORK_MOUNT/${NETWORK_FOLDERS[i]} Done ***************"
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
