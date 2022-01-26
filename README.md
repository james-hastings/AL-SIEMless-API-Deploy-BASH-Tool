Alert Logic SIEMless Threat Management API Deployment BASH Tool

[![Git](https://app.soluble.cloud/api/v1/public/badges/13961f5d-c192-407e-97ef-c69860cff11d.svg?orgId=367099919619)](https://app.soluble.cloud/repos/details/github.com/james-hastings/al-siemless-api-deploy-bash-tool?orgId=367099919619)  

Requirements: Linux / macOS / Windows w/Ubuntu CLI, jq (you must install the jq JSON formatting tool), you also need to have already created the IAM cross-account role (and have the Role ARN and External ID handy).

Credentials:  By default, this script will prompt you for a username and password, this tool does not support MFA tokens.  It does hover support API key credentials, and will accept those in place of the normal username and password.


######
######
To run: Download .sh file and then make "chmod +x" command against file to make it executable, then "./path_to_.sh_file"

The tool prompts you to input your login credentials (used to pull the API token).  

Once that is done you are prompted to enter a name for your credential set (this really doesn't matter as it appears no where in the UI, but never-the-less needs a value).

You are then prompted for the IAM Role ARN, followed by the External ID value. (These come from the IAM cross-account role setup separatly from this)

Next, you must specify wether consolidated/cross-account CloudTrail logging is leveraged. (If your CloudTrail publishes to a bucket owned by the same account, select "No").  If you select yes, you will be prompted to enter a second credential name/ARN/external id.

After the credentials section finishes up you are prompted to enter a deployment name - this is the value that will show on the deployments page in the Alert Logic console (this can be changed later via the UI or API).

Next, enter the AWS Region that the Cloud Trail exists in.  Even if your CloudTrail is global it still exists in a specific region - it's easiest to just login to AWS and check.  The format should be standard AWS format like "us-east-X" or "eu-west-X".

###########
WARNING !!!!
###########
       V  V
         V
While you are able to select Automatic deployment mode, it lacks testing, and 100% results in IDS appliances being spun up in every in-use availability zone of each AWS region you speciy in the upcoming scope section.  Why not just use the UI if you're going Automatic?

/warning

You are required to set at least one scope item - this can be either an AWS region or a scpecific VPC.  For the Region you only need to enter the normal AWS formatted region like "us-east-1", the tool will take care of the rest.  For the VPC, you must enter in the AWS region like before, but then also the VPC-id in the format (vpc-xxxxxxxxxx).

Once you finish the first credential you're pormpted to either add additional scope assets or move on.

If the tool is successful, you should see some JSON deployment information pop up, otherwise there should be very limited return.

You are given the option to write a log file - this basically summarizes all the input as well as the API output of various stages that are not exposed during the tools usage, but are valuable from a toubleshooting standpoint.




