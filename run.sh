#!/bin/bash

# Set sane bash defaults
set -o errexit
set -o pipefail

OPTION="$1"
S3PATH=${S3PATH:?"S3_PATH required"}
S3CMDPARAMS=${S3CMDPARAMS}

S3CFGFILE="/root/.s3cfg"
LOCKFILE="/tmp/s3cmd.lock"
LOG="/var/log/cron.log"

trap "rm -f $LOCKFILE" EXIT

if [ ! -e $LOG ]; then
  touch $LOG
fi

if [[ $OPTION = "start" ]]; then
  ACCESS_KEY=${ACCESS_KEY:?"ACCESS_KEY required"}
  SECRET_KEY=${SECRET_KEY:?"SECRET_KEY required"}
  CRON_SCHEDULE=${CRON_SCHEDULE:-0 * * * *}

  if [ ! -e $S3CFGFILE ]; then
    echo "Configuring S3CMD"
    echo -e "${ACCESS_KEY}\n${SECRET_KEY}\n\n\n\n\n\n\n\nn\ny\n" | \
      /usr/bin/s3cmd --configure
  fi

  echo "Found the following files and directores mounted under /data:"
  echo
  ls -F /data
  echo

  CRONFILE="/etc/cron.d/s3backup"
  if [ ! -e $CRONFILE ]; then
    echo "Adding CRON schedule: $CRON_SCHEDULE"
  
    CRONENV=""
    CRONENV="$CRONENV S3PATH=$S3PATH"
    CRONENV="$CRONENV S3CMDPARAMS=\"$S3CMDPARAMS\""
  
    echo "$CRON_SCHEDULE root $CRONENV bash /run.sh backup" >> $CRONFILE
  fi

  echo "Starting CRON scheduler: $(date)"
  cron
  exec tail -f $LOG 2> /dev/null

elif [[ $OPTION = "backup" ]]; then
  echo "Starting sync: $(date)" | tee $LOG

  if [ -f $LOCKFILE ]; then
    echo "$LOCKFILE detected, exiting! Already running?" | tee -a $LOG
    exit 1
  else
    touch $LOCKFILE
  fi

  echo "Executing s3cmd sync $S3CMDPARAMS /data/ $S3PATH..." | tee -a $LOG
  /usr/bin/s3cmd sync $S3CMDPARAMS /data/ $S3PATH 2>&1 | tee -a $LOG
  rm -f $LOCKFILE
  echo "Finished sync: $(date)" | tee -a $LOG

else
  echo "Unsupported option: $OPTION" | tee -a $LOG
  exit 1
fi
