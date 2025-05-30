#!/bin/bash

# This script updates the local repository with the latest changes from the remote repository.
# It also checks the nginx configuration file for syntax errors and reloads the nginx service if there are no errors.
NGINX_PATH="/etc/nginx"  # Replace with your nginx configuration file path
LOG_FILE="/var/log/nginx/update.log"  # Replace with your log file path

DATE=$(date '+%Y-%m-%d %H:%M:%S')

# Fetch the latest info from origin
git fetch origin
if [ $? -ne 0 ]; then
    echo "[$DATE] Failed to fetch the latest changes from the repository." | tee -a "$LOG_FILE"
    exit 1
fi

# Compare local and remote HEAD
LOCAL=$(git rev-parse @)
REMOTE=$(git rev-parse @{u})
BASE=$(git merge-base @ @{u})

if [ "$LOCAL" = "$REMOTE" ]; then
    # Up-to-date, no changes to apply
elif [ "$LOCAL" = "$BASE" ]; then
    # Update the local repository
    git pull origin main  
    if [ $? -ne 0 ]; then
        echo "[$DATE] Failed to pull the latest changes from the repository." | tee -a "$LOG_FILE"
        exit 1
    fi

    echo "[$DATE] Local repository updated successfully." | tee -a "$LOG_FILE"

    # Copy configuration files to nginx conf.d directory
    cp -r "./conf.d/"* "$NGINX_PATH/conf.d/"
    if [ $? -ne 0 ]; then
        echo "[$DATE] Failed to copy configuration files to $NGINX_PATH/conf.d/." | tee -a "$LOG_FILE"
        exit 1
    fi

    # Check nginx configuration syntax
    nginx -t
    if [ $? -eq 0 ]; then
        echo "[$DATE] Nginx configuration syntax is valid." | tee -a "$LOG_FILE"
        systemctl reload nginx
        if [ $? -eq 0 ]; then
            echo "[$DATE] Nginx service reloaded successfully." | tee -a "$LOG_FILE"
        else
            echo "[$DATE] Failed to reload nginx service." | tee -a "$LOG_FILE"
            exit 1
        fi
    else
        echo "[$DATE] Nginx configuration syntax error." | tee -a "$LOG_FILE"
        exit 1
    fi
fi
