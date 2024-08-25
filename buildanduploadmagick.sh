#!/bin/bash

# Global Variables
IMAGEMAGICK_FOLDER="ImageMagick-7.1.1"
BUILT_FILENAME="imagemagic"
TAR_PATH="ImageMagickBuildPackages"
PREFIX_NAME="outputMagic"

BASE_DIR="$HOME/${IMAGEMAGICK_FOLDER}"
BASE_FILENAME="${BUILT_FILENAME}_$(date +"%Y%m%d_%H%M%S")"

DEFAULT_CONFIGURE_DIR="${BASE_DIR}"
DEFAULT_TAR_PATH="${HOME}/${TAR_PATH}"
DEFAULT_PREFIX="${HOME}/${PREFIX_NAME}"

# Default values for command-line arguments
CONFIGURE_DIR="$DEFAULT_CONFIGURE_DIR"
TAR_PATH="$DEFAULT_TAR_PATH"
PREFIX="$DEFAULT_PREFIX"
FILE_TO_UPLOAD="${TAR_PATH}/${BASE_FILENAME}.tar"

# Parse command-line arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -d|--configure-dir) CONFIGURE_DIR="$2"; shift ;;
        -t|--tar-path) TAR_PATH="$2"; shift ;;
        -p|--prefix) PREFIX="$2"; shift ;;
        --help) echo "Usage: $0 [-d <dir> | --configure-dir <dir>] [-t <path> | --tar-path <path>] [-p <prefix> | --prefix <prefix>] -f <file> | --file <file>"; exit 0 ;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done

build_and_package() {
    local configure_dir="$1"
    local tar_path="$2"
    local prefix="$3"

    if [ ! -d "$configure_dir" ]; then
        echo "Directory '$configure_dir' not found."
        return 1
    fi

    if [ ! -d "$tar_path" ]; then
        echo "Directory '$tar_path' not found. Creating it."
        mkdir -p "$tar_path" || return 1
    fi

    if [ ! -d "$prefix" ]; then
        echo "Directory '$prefix' not found. Creating it."
        mkdir -p "$prefix" || return 1
    fi

    # Configure, build, and install
    cd "$configure_dir" || return 1
    ./configure --disable-shared --enable-static --prefix="$prefix" || return 1
    make || return 1
    make install || return 1

    cd $HOME
    tar -cvf "${tar_path}/${BASE_FILENAME}.tar" "${prefix}"
}

upload_file() {
    local file_to_upload="$1"

    if [ ! -f "$file_to_upload" ]; then
        echo "File '$file_to_upload' not found."
        return 1
    fi

    lftp -e "set ftp:ssl-allow yes; put ${file_to_upload} -o ${FTP_PATH}/$(basename ${file_to_upload}); bye" \
         -u "${FTP_USER},${FTP_PASS}" \
         ${FTP_SERVER}

    if [ $? -eq 0 ]; then
        echo "Upload successful."
        return 0
    else
        echo "Upload failed."
        return 1
    fi
}

# Load environment variables from the file
if [ -f "ftpserver.env" ]; then
    export $(grep -v '^#' ftpserver.env | xargs)
else
    echo "ftpserver.env file not found."
    exit 1
fi

# Check if required environment variables are set
if [ -z "$FTP_SERVER" ] || [ -z "$FTP_USER" ] || [ -z "$FTP_PASS" ] || [ -z "$FTP_PATH" ]; then
    echo "One or more environment variables are missing."
    exit 1
fi

# Call the build and packaging function
if build_and_package "$CONFIGURE_DIR" "$TAR_PATH" "$PREFIX"; then
    # If build_and_package succeeds, call the upload function
    upload_file "$FILE_TO_UPLOAD"
else
    # If build_and_package fails, print an error message and exit
    echo "Build and packaging failed."
    exit 1
fi

exit $?
