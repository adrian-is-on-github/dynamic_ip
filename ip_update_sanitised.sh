#!/bin/bash

# Variables
HOSTED_ZONE="<<<PUT_YOUR_HOSTED_ZONE_ID_HERE>>>"
LOG_FILE="ip_update.log"
echo -n >> $LOG_FILE # Append nothing or create file if not present
LOG_FILE_BACKUP="$LOG_FILE-backup.log"
MY_IP=$(curl -s https://ipinfo.io/ip)
TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")
LAST_IP=$(grep "Oh goodie, looks like the IP has changed from" $LOG_FILE | awk '{print $NF}' | tail -1)

# Create logfile if not present
touch $LOG_FILE

# Function to check if the public IP address returned is valid
function validate_ip() {
    local ip=$1
    local valid_ip_regex="^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])$"

    if [[ ${ip} =~ ${valid_ip_regex} ]]; then
        return 0
    else
        return 1
    fi
}
# Call the validate_ip function
if ! validate_ip "$MY_IP"; then
    echo "$TIMESTAMP - The returned IP address $MY_IP is not valid. Exiting till next time..." >> $LOG_FILE 2>&1
    exit 1
fi

# Check to see if IP has changed
if [ "$MY_IP" == "$LAST_IP" ]
then
    echo -e "$TIMESTAMP - The IP address hasn't changed, so I'm going back to bed.\n" #>> log_ip_update.txt #feel free to uncomment this line if you want to see this message every time it runs
    exit
fi

# Here's where we actually do stuff
echo "$TIMESTAMP - Oh goodie, looks like the IP has changed from $LAST_IP to $MY_IP" >> $LOG_FILE 2>&1

# Create a new route53 json file to update the record
cat > ~/route53_update.json << EOL
{
    "Comment": "Update record to reflect new IP address of home router",
    "Changes": [
        {
            "Action": "UPSERT",
            "ResourceRecordSet": {
                "Name": "<<<PUT_YOUR_DNS_RECORD_HERE>>>",
                "Type": "A",
                "TTL": 300,
                "ResourceRecords": [
                    {
                        "Value": "$MY_IP"
                    }
                ]
            }
        }
    ]
}
EOL
# Send your updated file to route53
aws route53 change-resource-record-sets --hosted-zone-id $HOSTED_ZONE --change-batch file://~/route53_update.json

# Remove the route53 json file
rm -f ~/route53_update.json

# Send info to logs
echo -e "Your IP address change was sent to Route53\n" >> $LOG_FILE 2>&1


### Log rotation and cleanup ###
# This will create the backup logfile, overwriting the existing backup...
# ...limiting the log size to current + backup_file only

# Check if log file size is greater than 100KB (100*1024 bytes), and if so, rotate it
if [ -e "$LOG_FILE" ] && [ $(stat -f%z "$LOG_FILE") -gt $((100*1024)) ]; then
    mv $LOG_FILE $LOG_FILE_BACKUP
fi
