IMAGEMAGICK_FOLDER="ImageMagick-7.1.1"
BUILT_FILENAME="imagemagic"
TAR_PATH="ImageMagickBuildPackages"
PREFIX_NAME="outputMagic"

BASE_DIR="{$HOME}/{$IMAGEMAGICK_FOLDER}"
BASE_FILENAME="{$BUILT_FILENAME}_$(date +"%Y%m%d_%H%M%S")"

DEFAULT_CONFIGURE_DIR="${BASE_DIR}"
DEFAULT_TAR_PATH="${HOME}/${TAR_PATH}"
DEFAULT_PREFIX="${HOME}/${{PREFIX_NAME}}"

TAR_PATH="${3:-$DEFAULT_TAR_PATH}"
CONFIGURE_DIR="${2:-$DEFAULT_CONFIGURE_DIR}"
PREFIX="${4:-$DEFAULT_PREFIX}"


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
  # Ensure the prefix directory exists
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

if [ -f "ftpserver.env" ]; then
  export $(cat ftpserver.env | xargs)
else
  echo "ftpserver.env file not found."
  exit 1
fi

if [ -z "$FTP_SERVER" ] || [ -z "$FTP_USER" ] || [ -z "$FTP_PASS" ] || [ -z "$FTP_PATH" ]; then
  echo "One or more environment variables are missing."
  exit 1
fi

if [ $# -ne 1 ]; then
  echo "Usage: $0 <file-to-upload>"
  exit 1
fi

FILE_TO_UPLOAD="$1"

if build_and_package $CONFIGURE_DIR; then
     upload_file "$FILE_TO_UPLOAD"
else
  echo "Build and packaging failed."
  exit 1
fi

exit $?
