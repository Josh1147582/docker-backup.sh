# docker-backup.sh
Stop, export, compress, and restart docker containers.

 docker-backup.sh stops all running containers, exports them and gzips them to the
    current directory, then restarts the previously running containers in the reverse
    order of which they were stopped.

    This script assumes it is being run as root, or the current user is in the docker group.

    Usage: ./docker-backup.sh [args]

    -a    Backup all containers, not just running containers. Only running containers will be
          restarted after backup (unless otherwise specified by -n)

    -h    Print this help message.

    -n    Don't restart containers after backup

    -o OUTDIR    Backups are sent to OUTDIR, rather than the current directory

    -v VOLUME (-v SECONDVOLUME -v THIRDVOLUME...)]
            Include volume directories with your backup. These are made once the container is
            stopped to avoid corruption.
