#!/bin/bash

OPTIND=1

VOLUMES=''
ALLFLAG=''
OUTDIR='./'
NOAUTORESTART=''

# get arguments
while getopts "h?v:o:na" opt; do
    case "$opt" in
        h|\?)
            echo "
    docker-backup.sh stops all running containers, exports them and gzips them to the
    current directory, then restarts the previously running containers in the reverse
    order of which they were stopped.

    This script assumes it is being run as root, or the current user is in the docker group.

    Usage: "$0 "[args]

    -a    Backup all containers, not just running containers. Only running containers will be
          restarted after backup (unless otherwise specified by -n)

    -h    Print this help message.

    -n    Don't restart containers after backup

    -o OUTDIR    Backups are sent to OUTDIR, rather than the current directory

    -v VOLUME (-v SECONDVOLUME -v THIRDVOLUME...)]
            Include volume directories with your backup. These are made once the container is
            stopped to avoid corruption.
"
            exit 0
            ;;
        v)  VOLUMES=$VOLUMES\;$OPTARG
            ;;
        o) OUTDIR=$OPTARG
            ;;
        n) NOAUTORESTART='1'
            ;;
        a) ALLFLAG='-a'
    esac
done

# Cleanup from getopts
shift $((OPTIND-1))
[ "$1" = "--" ] && shift


# Check if outdir exists, else (try to) create it
if [ ! -d $OUTDIR ]
then
    mkdir $OUTDIR
fi

# Check or write access
if [ ! -w $OUTDIR ]
then
    echo $OUTDIR is not writable. Exiting...
    exit 1
fi

# Remove first semicolon from volumes list
VOLUMES=$(echo $VOLUMES | sed 's/^.//')

# Get requested list of containers
CONTAINERS=$(docker ps $ALLFLAG --format '{{.Names}}' | sed ':a;N;$!ba;s/\n/ /g')

RUNNINGCONTAINERS=''
if [ ! $NOAUTORESTART ]
then
    RUNNINGCONTAINERS=$(docker ps --format '{{.Names}}' | sed ':a;N;$!ba;s/\n/ /g' | awk '{for(i=NF;i>0;--i)printf "%s%s",$i,(i>1?OFS:ORS)}')
fi

# Stop all containers
echo Stopping containers...
for i in $CONTAINERS
do
    docker stop $i
done

# Wait for all to be stopped
wait

# Export each container
echo Exporting containers...
for i in $CONTAINERS
do
    docker export $i | gzip -c > $OUTDIR/$i-$(date +%Y%m%d-%H%M%S).tar.gz && echo "Exported "$i &
done

wait

# Get specified volumes delimited by semicolons
if [ $VOLUMES ]
then
    echo Backing up volumes...
    OLDIFS=$IFS
    IFS=';'

    for i in $VOLUMES
    do
        tar czf $OUTDIR/$(basename $i).tar.gz $i && echo "Backed up "$i &
    done

    IFS=$OLDIFS
fi

# Restart previously running containers (if any were given or it was requested)
if [ ! $NOAUTORESTART ]
then
    echo Restarting previously running containers...
        for i in $RUNNINGCONTAINERS
        do
        docker start $i &
    done

    wait

fi
