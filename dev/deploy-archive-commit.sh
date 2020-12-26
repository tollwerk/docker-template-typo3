#!/bin/bash

NOW=$(date +%Y%m%d-%H%M%S)
TARGET=
COMMIT=
REPOSITORY=
HOST=
USER=
PORT=22
ARTIFACTS=

for i in "$@"; do
    case $i in
    -t=* | --target=*)
        TARGET="${i#*=}"
        ;;
    -c=* | --commit=*)
        COMMIT="${i#*=}"
        ;;
    -r=* | --repository=*)
        REPOSITORY="${i#*=}"
        ;;
    -h=* | --host=*)
        HOST="${i#*=}"
        ;;
    -u=* | --user=*)
        USER="${i#*=}"
        ;;
    -p=* | --port=*)
        PORT="${i#*=}"
        ;;
    -a=* | --artifacts=*)
        ARTIFACTS="${i#*=}"
        ;;
    -b=* | --branch=*)
        BRANCH="${i#*=}"
        ;;
    *)
        # unknown option
        ;;
    esac
done

if [ "$TARGET" = "" ]; then
    echo "Please provide a remote target directory (-t / --target)"
    exit 1
fi
if [ "$COMMIT" = "" ]; then
    echo "Please provide an exact commit to deploy (-c / --commit)"
    exit 2
fi
if [ "$REPOSITORY" = "" ]; then
    echo "Please provide the SSH repository URL (-r / --repository)"
    exit 3
fi
if [ "$HOST" = "" ]; then
    echo "Please provide the SSH host (-h / --host)"
    exit 4
fi
if [ "$USER" = "" ]; then
    echo "Please provide the SSH host (-u / --user)"
    exit 5
fi
if [ "$PORT" = "" ]; then
    echo "Please provide the SSH port (-p / --port)"
    exit 6
fi
if [ "$BRANCH" = "" ]; then
    echo "Please provide the branch name to deploy (-b / --branch)"
    exit 7
fi

RELEASES="$TARGET/releases"
RELEASE_DIR="$RELEASES/$NOW"
WORK_DIR="$RELEASES/work"
RSYNC_ARTIFACTS=""

# Clean and validate artifacts
for artifact in $ARTIFACTS; do
    abs_artifact=$(realpath "$artifact" 2>/dev/null)
    if [ -e "$abs_artifact" ]; then
        RSYNC_ARTIFACTS="$RSYNC_ARTIFACTS $(pwd)/./$artifact"
    fi
done

# Clone and prepare the repository on the remote server
CMD="mkdir -p '$RELEASE_DIR' && git clone --depth 1 $REPOSITORY '$WORK_DIR' && cd '$WORK_DIR' && git reset --hard '$COMMIT'"
CMD="$CMD && ( git archive $COMMIT | tar x -C '$RELEASE_DIR') && cd '$RELEASE_DIR'"
CMD="$CMD && curl --show-error --silent "https://getcomposer.org/installer" | php"
CMD="$CMD && php7.4 composer.phar install -o"
CMD="$CMD && rm -rf '$RELEASE_DIR/public/fileadmin' && ln -nfs '$TARGET/fileadmin' '$RELEASE_DIR/public/fileadmin'"
CMD="$CMD && rm -rf '$RELEASE_DIR/public/typo3conf/LocalConfiguration.php' && ln -nfs '$TARGET/LocalConfiguration.php' '$RELEASE_DIR/public/typo3conf/LocalConfiguration.php'"
CMD="$CMD && rm -rf '$RELEASE_DIR/public/typo3conf/PackageStates.php' && ln -nfs '$TARGET/PackageStates.php' '$RELEASE_DIR/public/typo3conf/PackageStates.php'"
echo $CMD
ssh -2C -p$PORT "$USER@$HOST" "$CMD"
echo "rm -rf '$WORK_DIR'"
ssh -2C -p$PORT "$USER@$HOST" "rm -rf '$WORK_DIR'"

# Transfer build artifacts
if [ "$RSYNC_ARTIFACTS" != "" ]; then
    echo "rsync -azRvL --no-o --no-g  -e \"ssh -p $PORT\" --exclude='.gitignore' $RSYNC_ARTIFACTS \"$USER@$HOST:$RELEASE_DIR\""
    rsync -azRvL --no-o --no-g -e "ssh -p $PORT" --exclude='.gitignore' $RSYNC_ARTIFACTS "$USER@$HOST:$RELEASE_DIR"
fi

# Finalize the deployment
CMD="cd '$RELEASE_DIR' && php7.4 vendor/bin/typo3cms cache:flush"
CMD="$CMD && ln -nfs '$RELEASE_DIR' '$TARGET/current.tmp' && mv -Tf '$TARGET/current.tmp' '$TARGET/current'"
CMD="$CMD && ( PURGE=\$(ls -dt '$RELEASES'/* | tail -n +3); rm -rf \$PURGE; )"
echo $CMD
ssh -2C -p$PORT "$USER@$HOST" "$CMD"
