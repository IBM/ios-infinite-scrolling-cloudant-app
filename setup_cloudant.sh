#!/bin/sh

function getCredentialsPath {
    for p in InfiniteScrollingwithCloudantNoSQLforiOS*/ ; do
        p=$(echo "${p%%Test*}")
        p=$(echo "${p%%UI*}")
        p=$(echo "${p%%\.*}")
        echo ./$p/BMSCredentials.plist
        break
    done
}

CREDENTIALS_PATH=$(getCredentialsPath)
PLIST=$(<$CREDENTIALS_PATH)
CLOUDANT_URL=$(sed 's/.*cloudantUrl<\/key> <string>\([^<]*\)<\/string>.*/\1/' <<< $PLIST)
DATABASE_NAME="countries"
DATABASE_URL=$CLOUDANT_URL"/"$DATABASE_NAME

# Create Database
echo "Creating Database\n-----------------"
CREATE_DB_RESULT=$(curl --write-out %{http_code} --silent --output /dev/null -X PUT $DATABASE_URL)
if [ $CREATE_DB_RESULT -eq "201" ]
then
    echo "RESULT: Successfully created database."
else
    echo "ERROR: Could not create database (Error Code $CREATE_DB_RESULT)."
fi

echo "\n"

# Upload Data
echo "Uploading Data\n--------------"
UPLOAD_RESULT=$(curl --write-out %{http_code} --silent --output /dev/null -X POST -H "Content-Type: application/json" -d @./countries.json $DATABASE_URL/_bulk_docs)
if [ $UPLOAD_RESULT -eq "201" ]
then
    echo "RESULT: Successfully uploaded data."
else
    echo "ERROR: Could not create database (Error Code $UPLOAD_RESULT)."
fi
