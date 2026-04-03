# arrs-to-qnap-simmons

Syncs media files from local staging directories to a CIFS/SMB network share. Runs in a loop, checking for new files every 2 minutes.

## Scripts

### `sync-from-staging.sh` (container command: `run-sync`)

Mounts a network share and rsyncs media from the local arrs staging location to the network share. Requires three CLI flags:

| Flag | Description | Example |
|---|---|---|
| `--network-share` | The CIFS/SMB network share path | `//plexd.randrservices.com/PlexData` |
| `--network-mount` | The local mount point for the share | `/mnt/qnap` |
| `--arrs-location` | The local directory where arrs stages media | `/srv/media/` |

### `staging-folders.sh` (container command: `update-staging-folders`)

Stages media from `/srv/media/movies` and `/srv/media/tvshows` into separate destination folders (`PLEX26` and `NAS`) for independent syncing.

## Build

```bash
docker build -t arrs-to-qnap-simmons .
```

## Run

The container requires `SYNC_USERNAME` and `SYNC_PASSWORD` environment variables for CIFS authentication, and `--privileged` (or `SYS_ADMIN` capability) to mount network shares.

### Running `run-sync`

```bash
docker run --privileged \
  -e SYNC_USERNAME=myuser \
  -e SYNC_PASSWORD=mypassword \
  arrs-to-qnap-simmons \
  run-sync \
    --network-share "//plexd.randrservices.com/PlexData" \
    --network-mount "/mnt/qnap" \
    --arrs-location "/srv/media/"
```

### Running `update-staging-folders`

```bash
docker run \
  arrs-to-qnap-simmons \
  update-staging-folders
```

### Running both together

You can run the staging step in the background and then start the sync:

```bash
docker run --privileged \
  -e SYNC_USERNAME=myuser \
  -e SYNC_PASSWORD=mypassword \
  arrs-to-qnap-simmons \
  bash -c "update-staging-folders & run-sync --network-share '//plexd.randrservices.com/PlexData' --network-mount '/mnt/qnap' --arrs-location '/srv/media/'"
```