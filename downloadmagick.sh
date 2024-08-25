#!/bin/bash

# Load environment variables from a file
if [ -f "secrets.env" ]; then
  export $(cat secrets.env | xargs)
else
  echo "secrets.env file not found."
  exit 1
fi

# Check if required environment variables are set
if [ -z "$FTP_SERVER" ] || [ -z "$FTP_USER" ] || [ -z "$FTP_PASS" ] || [ -z "$FTP_PATH" ]; then
  echo "One or more environment variables are missing."
  exit 1
fi

# File to download
FILE_TO_DOWNLOAD="artifact.tar"

# Download the file from the FTPS server using lftp
lftp -e "set ftp:ssl-allow yes; cd ${FTP_PATH}; get ${FILE_TO_DOWNLOAD}; bye" \
     -u "${FTP_USER},${FTP_PASS}" \
     ${FTP_SERVER}

# Check if download was successful
if [ $? -eq 0 ]; then
  echo "Download successful."
else
  echo "Download failed."
  exit 1
fi
