#!/bin/bash
# GCloud Filestore Backup - Backups via scheduler
# AUTHOR : chris@greenlightgroup.com
# SOURCE : https://cloud.google.com/filestore/docs/scheduling-backups
# 

################################################################################
#####                           SERVICE ACCOUNTS                           #####
################################################################################
# Create Service Accounts
gcloud iam service-accounts create schedulerunner \
 --display-name="Service Account for FS Backups-Scheduler"
gcloud iam service-accounts create backupagent \
 --display-name="Service Account for FS Backups-GCF"
gcloud iam service-accounts list

### GKE Scheduler for NFS Backup
export PROJECT_ID=`gcloud config get-value core/project`
export PROJECT_NUMBER=`gcloud projects describe $PROJECT_ID --format='value(projectNumber)'`
export SCHEDULER_SA=service-$PROJECT_NUMBER@gcp-sa-cloudscheduler.iam.gserviceaccount.com
export SCHEDULER_CLIENT_SA=schedulerunner@$PROJECT_ID.iam.gserviceaccount.com
export GCF_CLIENT_SA=backupagent@$PROJECT_ID.iam.gserviceaccount.com
export FS_ZONE=europe-west1-b
export INSTANCE_NAME=gcp6133-p-file01
export SHARE_NAME=gcp6133_p_nfs01
export FS_BACKUP_LOCATION=europe-west1


### CREATE GCP FUNCTION
#https://cloud.google.com/filestore/docs/scheduling-backups

PROJECT_ID='us102173-p-sis-bsys-6133'
SOURCE_INSTANCE_ZONE='europe-west1-b'
SOURCE_INSTANCE_NAME='gcp6133-p-file01'
SOURCE_FILE_SHARE_NAME='gcp6133_p_nfs01'
BACKUP_REGION='europe-west1'

import google.auth
import google.auth.transport.requests
from google.auth.transport.requests import AuthorizedSession
import time
import requests
import json

credentials, project = google.auth.default()
request = google.auth.transport.requests.Request()
credentials.refresh(request)
authed_session = AuthorizedSession(credentials)

def get_backup_id():
    return "p-backup-" + time.strftime("%Y%m%d-%H%M%S")

def create_backup(request):
    trigger_run_url = "https://file.googleapis.com/v1beta1/projects/{}/locations/{}/backups?backupId={}".format(PROJECT_ID, BACKUP_REGION, get_backup_id())
    headers = {
      'Content-Type': 'application/json'
    }
    post_data = {
      "description": "my new backup",
      "source_instance": "projects/{}/locations/{}/instances/{}".format(PROJECT_ID, SOURCE_INSTANCE_ZONE, SOURCE_INSTANCE_NAME),
      "source_file_share": "{}".format(SOURCE_FILE_SHARE_NAME)
    }
    print("Making a request to " + trigger_run_url)
    r = authed_session.post(url=trigger_run_url, headers=headers, data=json.dumps(post_data))
    data = r.json()
    print(data)
    if r.status_code == requests.codes.ok:
      print(str(r.status_code) + ": The backup is uploading in the background.")
    else:
      raise RuntimeError(data['error'])

###END SCRIPT


#####
gcloud beta scheduler jobs create http fsbackupschedule \
    --schedule "15 23 * * *" \
    --http-method=GET \
    --uri=https://$BACKUP_REGION-$PROJECT_ID.cloudfunctions.net/fsbackup \
    --oidc-service-account-email=$SCHEDULER_CLIENT_SA    \
    --oidc-token-audience=https://$BACKUP_REGION-$PROJECT_ID.cloudfunctions.net/fsbackup


gcloud iam service-accounts add-iam-policy-binding $SCHEDULER_CLIENT_SA \
    --member=serviceAccount:$SCHEDULER_SA \
    --role=roles/cloudscheduler.serviceAgent

gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member=serviceAccount:$GCF_CLIENT_SA \
    --role=roles/file.editor

gcloud functions add-iam-policy-binding fsbackup \
    --member serviceAccount:$SCHEDULER_CLIENT_SA \
    --role roles/cloudfunctions.invoker