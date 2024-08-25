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

# Check if a file name was provided as an argument
if [ $# -ne 1 ]; then
  echo "Usage: $0 <file-to-upload>"
  exit 1
fi

# File to upload
FILE_TO_UPLOAD="$1"

# Check if the file exists
if [ ! -f "$FILE_TO_UPLOAD" ]; then
  echo "File '$FILE_TO_UPLOAD' not found."
  exit 1
fi

# Upload the file to the FTPS server using lftp
lftp -e "set ftp:ssl-allow yes; put ${FILE_TO_UPLOAD} -o ${FTP_PATH}/$(basename ${FILE_TO_UPLOAD}); bye" \
     -u "${FTP_USER},${FTP_PASS}" \
     ${FTP_SERVER}

# Check if upload was successful
if [ $? -eq 0 ]; then
  echo "Upload successful."
else
  echo "Upload failed."
  exit 1
fi
