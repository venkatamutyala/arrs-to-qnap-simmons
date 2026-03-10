#!/bin/bash

set -e
# To copy the arrs data from arrs to multiple devices without missed data is a multi step process
# 1. rsync and delete the arrs data from the arrs server to a the to-others-all folder
# 2. copy from the to-other folder to a folder for each of the other servers to-others-<servername>
# 3. erase the data in the to-others folder (not subfolders)
# 4. rsync and delete from the to-others-<servername> to that servers mount points
# 5. sleep for a while and repeat
#
# define the arrs data folder(s) and their location
ARRS_LOCATION="/srv/media/"
ARRS_FOLDERS=(
    "movies"
    "tvshows"
)
#
# define the to-others-all folder(s) and location
TO_OTHERS_LOCATION="/srv/media/others"
TO_OTHERS_FOLDERS=(
    "movies"
    "tvshows"
)
TO_OTHERS_SERVERS=(
    "PLEX26"
    "PLEXD"
)
#
# define the servers and their location, mount point, and folders
# plex26
PLEX26_SHARES="//plex26.randrservices.com/PlexData"
PLEX26_MOUNTS="/mnt/plex26"
PLEX26_FOLDERS=(
    "Movies"
    "TV Shows"
)
# plexd
PLEXD_SHARES="//plexd.randrservices.com/PlexData"
PLEXD_MOUNTS="/mnt/plexd"
PLEXD_FOLDERS=(
    "Movies"
    "TV Shows"
)
#
# Path to store the last run timestamp
LOG_FILE="log_run.txt"
# to echo into the logs
STARS="****************"
RSYNC_REMOVE=" --remove-source-files "
SLEEP_SECONDS=120
#
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

# do the rsync with lots of stuff around it
copy_with_log() {
    local from_location=$1
    local from_folder=$2
    local to_location=$3
    local to_folder=$4
    local extra_switches=$5
    # Current time in seconds since the epoch
    START_TIME=$(date '+%Y-%m-%d %H:%M:%S')

    # Record the current time as the last run time
    echo -n "START: ${START_TIME} " >> "$LOG_FILE"
    echo -n "START: ${START_TIME} "
    
    # check for files in the folder before doing any steps
    if [ -n "$(ls -A $from_location$from_folder 2>/dev/null)" ]
    then
        echo
        echo "$STARS $from_location$from_location to $from_location$from_location Starting $STARS"
        # show the files and folders we will copy
        ls "$from_location$from_location" || true
        # rsync the files and folders
        rsync -r -ah -P $extra_switches $from_location/$from_folder/ $to_location/$to_folder || true
        if [ $extra_switches = $RSYNC_REMOVE ]
            find "$from_location$from_folder" -mindepth 1 -type d -empty -delete || true
        fi
        echo "$STARS $from_location$from_folder to $to_location/$to_folder Done $STARS"
    else
        echo -n " No files $from_location$from_folder "
    fi

    FINISH_TIME=$(date '+%Y-%m-%d %H:%M:%S')
    echo " FINISH: ${FINISH_TIME}" >> "$LOG_FILE"
    echo " FINISH: ${FINISH_TIME} "
}


# log disk usage
df -h

######################
# Step 1
# 1. rsync and delete the arrs data from the arrs server to a the to-others-all folder
######################
    for i in "${!ARRS_FOLDERS[@]}"; do
        copy_with_log "$ARRS_LOCATION/" "${ARRS_FOLDERS[i]}" "$TO_OTHERS_LOCATION/" "${TO_OTHERS_FOLDERS[i]}" "$RSYNC_REMOVE"
    done

######################
# Step 2
# 2. copy from the to-other folder to a folder for each of the other servers to-others-<servername>
######################
    for i in "${!TO_OTHERS_FOLDERS[@]}"; do
        for j in "${!TO_OTHERS_SERVERS[@]}"; do
            copy_with_log "$TO_OTHERS_LOCATION/" "${TO_OTHERS_FOLDERS[i]}" "$TO_OTHERS_LOCATION/${!TO_OTHERS_SERVERS[j]}/" "${TO_OTHERS_FOLDERS[i]}" ""
        done
    done

######################
# Step 3
# 3. erase the data in the to-others folder (not subfolders)
######################
    for i in "${!TO_OTHERS_FOLDERS[@]}"; do
        find "$TO_OTHERS_LOCATION/${TO_OTHERS_FOLDERS[i]}" -mindepth 1 -type d -empty -delete || true
    done

######################
# Step 4
# 4. rsync and delete from the to-others-<servername> to that servers mount points
######################
    # Mount the shares to the specified mount points
    for i in "${!TO_OTHERS_SERVERS[@]}"; do
        mount_if_needed "${TO_OTHERS_SERVERS[i]}_SHARES" "${TO_OTHERS_SERVERS[i]}_MOUNTS"
        copy_with_log "$TO_OTHERS_LOCATION/" "${TO_OTHERS_FOLDERS[i]}" "${TO_OTHERS_SERVERS[i]}_MOUNTS/"  "${TO_OTHERS_FOLDERS[i]}_FOLDERS" "$RSYNC_REMOVE"
    done


######################
# Step 5
# 5. sleep for a while and repeat
######################
    # Sleep to avoid excessive CPU usage, then check again
    sleep SLEEP_SECONDS

done
