#!/bin/bash

#Requires .jq for use - make sure to install.
#PSTcore.jh

#Create a manual SIEMless deployment for AWS!

#This script will help you create the credential file in the AL backend and 
#then use it to create a manual deployment.

#You need to have already created the SIEMless manual IAM Role, and have the
#Role ARN and external ID values

clear

 #banner
echo -e "\n"
echo -e "    ___    __       _____ ____________  _____              "
echo -e "   /   |  / /      / ___//  _/ ____/  |/  / /__  __________"
echo -e "  / /| | / /       \__ \ / // __/ / /|_/ / / _ \/ ___/ ___/"
echo -e " / ___ |/ /___    ___/ // // /___/ /  / / /  __(__  |__  ) "
echo -e "/_/ _||/_____|_  |____/___/_____/_/  /_/__|___/____/____/  "
echo -e "   /   |  / __ \/  _/  / __ \___  ____  / /___  __  __     "
echo -e "  / /| | / /_/ // /   / / / / _ \/ __ \/ / __ \/ / / /     "
echo -e " / ___ |/ ____// /   / /_/ /  __/ /_/ / / /_/ / /_/ /      "
echo -e "/_/  |_/_/   /___/  /_____/\___/ .___/_/\____/\__, /       "
echo -e "                              /_/            /____/        \n\n"
 echo -e "\n Alert Logic Deployment Tool - 2019 - v1.0"


#slight pause for dramatic impact
sleep 2.5
                                                         

#Specify or get username
read -p "Enter AL User Email Address (Admin Required): " un
#un=""


#Capture password
read -s -p "Enter Password: " pw
#pw=""


#Specify api endpoint (US or UK)

		#endpoint='https://api.cloudinsight.alertlogic.co.uk'
		endpoint='https://api.cloudinsight.alertlogic.com'
		
		#Get token
		json="[`curl -s -X POST $endpoint/aims/v1/authenticate -u $un:$pw`]"
		auth_token=`echo $json | jq '.[] | (.authentication.token | tostring)' | tr -d '\"'`

clear

echo -e "\n Welcome to the SIEMless AWS Manual Deployment Creation Tool!\n\n\n"
echo -e " This BASH script automates the API deployment of an Alert\n Logic AWS Environment\n\n"
echo -e " Overall, a credential entry is added to the AL backend, and\n then an API call is made to create the deployment.\n\n\n"
read -p " Press return to continue" unused
clear
echo -e "\n\n\n If the AL account resides in the UK you must change\n the API endpoint in the script. Newport DC is UK.\n\n\n"
read -p " Press return to continue" unused

clear
echo -e "\n\n To begin, enter a name for your credential:\n"
read -p "" cred_name
echo -e "\n Enter the Role ARN: \n"
read -p "" role_arn
echo -e "\n Enter the External ID: \n"
read -p "" external_id

clear
echo -e "\n\n Creating the credential!\n\n"

#Create temp file for json info
(echo -e '{
    "credential": {
        "name": "'$cred_name'",
        "type": "iam_role",
        "iam_role": {
            "arn": "'$role_arn'",
            "external_id": "'$external_id'"
		}
	}
}')>cred.json

#API call to POST credential
api_pull_1="`curl -s -X POST -H "X-AIMS-Auth-Token:$auth_token" -d @cred.json https://api.cloudinsight.alertlogic.com/sources/v1/${external_id}/credentials`"

#Get credential ID and strip out the quotation marks
credential_id=`echo $api_pull_1 | jq .credential.id | tr -d '\"'`

#Remove temp file
rm cred.json

if [ "$credential_id" == "" ]
then
	echo -e "Something was incorrect - please check your input.\n\n\n"
	exit 

else

#write credential id to screen
echo $credential_id

echo -e "\n\n Credential created!\n\n\n"

read -p "Press return to continue" unused
fi


#Parse AWS account number out of primary role arn
role_arn_trimmed_1=`echo ${role_arn##*::}`
aws_id=`echo ${role_arn_trimmed_1%:*}`




x_setup=0
#check for cross-account ct setup
while [ $x_setup -lt 1 ]; do
clear
echo -e "\n\n Does this account send CloudTrail to another account (consolidated CT)?\n This is also commonly known as cross-account CloudTrail.\n\n"
echo -e "1) No\n2) Yes\n\n"
read -p "" ct_toggle

#if no, then do nothing
if [ $ct_toggle -eq 1 ]
	then ct_toggle=1
	x_setup=1

#if yes, then go ahead and grab 2nd role info
elif [ $ct_toggle -eq 2 ]
	then
		ct_toggle=2
		clear
		echo -e "\n\n Enter a cross-account CT credential name: \n"
		read -p "" x_account_cred_name
		echo -e "\n Enter the Role ARN: \n"
		read -p "" x_account_role_arn

clear
echo -e "\n\n Creating the credential!\n\n"

#Create temp file for json info
(echo -e '{
    "credential": {
        "name": "'$x_account_cred_name'",
        "type": "iam_role",
        "iam_role": {
            "arn": "'$x_account_role_arn'",
            "external_id": "'$external_id'"
		}
	}
}')>x_cred.json

#API call to POST x-account credential
api_pull_6="`curl -s -X POST -H "X-AIMS-Auth-Token:$auth_token" -d @x_cred.json https://api.cloudinsight.alertlogic.com/sources/v1/${external_id}/credentials`"

#Get credential ID and strip out the quotation marks
x_credential_id=`echo $api_pull_6 | jq .credential.id | tr -d '\"'`

#remove temp file
rm x_cred.json

#If there's no 2nd credential Id then somethings messed up - validation
if [ "$x_credential_id" == "" ]
then
	echo -e "Something was incorrect - please check your input.\n\n\n"
 

#if everything worked show the x-account credential ID
else
echo $x_credential_id

echo -e "\n\n Credential created!\n\n\n"
x_setup=1

read -p "Press return to continue" unused
fi

#validation
else
	echo -e "Make a valid selection"
fi

done



#Get the deployment information
clear

echo -e "\n\n Enter a deployment name: \n"
read -p "" deployment_name
echo -e "\n What AWS region is the CloudTrail in? (ex. us-west-2):\n"
read -p "" cd_install_region



# Validate manual or automatic
mode_loop=0
while [ $mode_loop -lt 1 ]; do
echo -e '\n Deployment mode:'
echo -e "\n 1) Manual\n 2) Automatic (Not Recommended)"
read -p "" mode

if [ $mode -eq 1 ]
then
	mode="manual"
	mode_loop=1

elif [ $mode -eq 2 ]
	then
		mode="automatic"
		mode_loop=1

	else
		clear
		echo -e '\n\n Sorry, you have to choose "manual" or "automatic"'
	fi
done
clear


#Get the first scope value - required
echo -e "\n\n Set scope / add regions and VPCs\n\n"

#choose either a region or a VPC
echo -e " Which type of scope asset do you want to add?\n"
echo -e " 1) AWS Region\n 2) VPC\n\n"
read -p "" scope_type
echo -e "\n"


#If you choose a region
if [ $scope_type -eq 1 ]
then
echo -e 'Enter the AWS region (ex. us-west-2): \n'
read -p "" scope_key

#combine into string variable
scope='{"type":"region","key":"/aws/'$scope_key'"}'

#if you choose a VPC
else
echo -e 'Enter the AWS region (ex. us-west-2): \n'
read -p "" scope_region
echo -e '\nEnter the VPC-id (ex. vpc-xxxxxxxxx): \n'
read -p "" scope_vpc_id

#combine into string variable
scope='{"type":"vpc","key":"/aws/'$scope_region'/vpc/'$scope_vpc_id'"}'
fi



#Implement counter for scope loop
i=0

#While i = 0 keep this loop to add more scope going
while [ $i -lt 1 ]; do
	echo -e "\n\nDo you need to add any other VPCs or regions?\n"
	echo -e "1) No\n2) Yes"
	read -p "" keep_going

#if 1, then, set i=1 and break loop
	if [ $keep_going -eq 1 ]
		then 
			i=1


#else keep loop going, prompt for scope type and key
elif [ $keep_going -eq 2 ]
	then
#choose either a region or a VPC
clear
echo -e "\n\n Which type of scope asset do you want to add?\n"
echo -e " 1) AWS Region\n 2) VPC\n\n"
read -p "" scope_type
echo -e "\n"


#If you choose a region
if [ $scope_type -eq 1 ]
then
echo -e 'Enter the AWS region (ex. us-west-2): \n'
read -p "" scope_key

#combine into string variable
add_on=',{"type":"region","key":"/aws/'$scope_key'"}'

#if you choose a VPC
else
echo -e 'Enter the AWS region (ex. us-west-2): \n'
read -p "" scope_region
echo -e '\nEnter the VPC-id (ex. vpc-xxxxxxxxx): \n'
read -p "" scope_vpc_id

#combine into string variable
add_on=',{"type":"vpc","key":"/aws/'$scope_region'/vpc/'$scope_vpc_id'"}'
fi

#take current scope value string and add additional string value to it.
scope+="${add_on}"

else 
echo -e "Make a valid selection"
fi
done

clear


#Piece together the .json text for the deployment creation
dc_counter=0
while [ $dc_counter -lt 1 ]; do
echo -e "\n\n Select AL datacenter account resides in: \n"
echo -e " 1) Denver\n 2) Ashburn\n 3) Newport"
read -p '' which_dc
if [ $which_dc -eq 1 ]
then
	al_dc="defender-us-denver"
	dc_counter=1
elif [ $which_dc -eq 2 ]
	then
		al_dc="defender-us-ashburn"
		dc_counter=1
elif [ $which_dc -eq 3 ]
	then
		al_dc="defender-uk-newport"
		dc_counter=1
	else
		echo -e "Make a valid selection!"
	fi
	done


#If/then for consolidated cloudtrail
#If you entered a second credential then post it
if [ $ct_toggle -eq 2 ]
then
	#push argument into separate file for uploading
(echo '{"name":"'$deployment_name'","platform":{"type":"aws","id":"'$aws_id'","monitor":{"enabled":true,"ct_install_region":"'$cd_install_region'"}},"mode":"'$mode'","enabled":true,"discover":true,"scan":true,"scope":{"include":['$scope']},"cloud_defender":{"enabled":false,"location_id":"'$al_dc'"},"credentials":[{"id":"'$credential_id'","purpose":"discover","version":"2018-01-01"},{"id":"'$x_credential_id'","purpose":"x-account-monitor","version":"2018-01-01"}]}')>deploy.json

clear

#make deployment create call - store in variable for log file
return_value="`curl -X POST -H "x-aims-auth-token: $auth_token" -d @deploy.json https://api.cloudinsight.alertlogic.com/deployments/v1/${external_id}/deployments | jq .`"
echo $return_value | jq .

#Otherwise, just post the one set of credentials
else
#push argument into separate file for uploading
(echo '{"name":"'$deployment_name'","platform":{"type":"aws","id":"'$aws_id'","monitor":{"enabled":true,"ct_install_region":"'$cd_install_region'"}},"mode":"'$mode'","enabled":true,"discover":true,"scan":true,"scope":{"include":['$scope']},"cloud_defender":{"enabled":false,"location_id":"'$al_dc'"},"credentials":[{"id":"'$credential_id'","purpose":"discover","version":"2018-01-01"}]}')>deploy.json

clear

#make api call to upload - encapsulate in variable to write log later
return_value="`curl -X POST -H "x-aims-auth-token: $auth_token" -d @deploy.json https://api.cloudinsight.alertlogic.com/deployments/v1/${external_id}/deployments | jq .`"
echo $return_value | jq .
fi


#Write a log file?
echo -e "\n\n\n Would you like to write the log file?\n 1) Yes\n 2) No"
read -p "" write_log

if [ $write_log -eq 1 ]
then
	(
		account_name="`curl -s -X GET $endpoint/aims/v1/$external_id/account -H "x-aims-auth-token: $auth_token" | jq .name | tr -d '\"'`"
		echo -e " Deployment log for $account_name - $external_id\n\n"
		echo -e "\n\n Account Name: $account_name"
		echo -e "\n AL CID: $external_id"
		echo -e "\n Deployment Name: $deployment_name"
		echo -e " \n Deployment Mode: $mode"
		echo -e "\n AL Datacenter: $al_dc"
		echo -e "\n AWS Account Number: $aws_id"
		echo -e "\n CloudTrail Trail Region: $cd_install_region"
		echo -e "\n\n\n Scope JSON:"
		echo -e " $scope"

		echo -e " \n\n\nCredential Input Info:"
		echo -e "     Credential Name: $cred_name"
		echo -e "     AWS IAM Role ARN: $role_arn"
		echo -e "     External ID: $external_id"
		echo -e "\n\n Credential Return Info:"
		echo $api_pull_1 | jq .
		if [ "$api_pull_6" == "" ]
		then
			unused="1"
		else
		echo -e "\n\n X-Account Credential Input Info:"
		echo -e "     Credential Name: $x_account_cred_name"
		echo -e "     AWS IAM Role ARN: $x_account_role_arn"
		echo -e "\n\n X-Account Credential Return Info:"
		echo $api_pull_6 | jq . 
	fi
		echo -e "\n\n Deployment Return Info:"
		echo $return_value | jq .
		echo -e "\n\n"
		) >al_api_deploy_log_${external_id}.txt

clear
echo -e "\n\n\n Log file written to: $PWD\n\n\n\n"
#remove temp file
rm deploy.json

else
#Remove the temporary deployment file created
rm deploy.json
fi