#!/bin/bash
#  
#  The purpose of this script is to make bulk provisioning of users 
#  in a given tenant
#  
#  Prerequisities: there must be python-keystone client installed
#  on a machine where script will be running.  
#  Both SERVICE_TOKEN and SERVICE_ENDPOINT are variables used by keystone client.
#  SERVICE_TOKEN can be found at '/etc/keystone/keystone.conf | grep admin_token' 
#  on machine that runs keystone.
#  
#  CSV file format:
#  <Firstname Lastname>,<user ID>,<user email>
#  example:
#  John Doe,jdoe,jdoe@email.com
#  

export SERVICE_TOKEN=68edcbfe5c7344a18f55fab1854c5040
export SERVICE_ENDPOINT=http://173.38.225.172:35357/v2.0
CSVFILE=user_names_emails.csv
CSVFILE_CUT=$(cat $CSVFILE | sed '/^#/ d') 
TENANT=openstack

#cleanup user accounts file log
echo > created_user_accounts.txt 

function pass_create(){
  echo date | md5sum | cut -c1-10
}


# check if requirements are met
if [[ ! ($(pip list | grep python-keystoneclient))]] && echo "Keystone client not installed!"
  then return
fi

if [[ ! (-f $CSVFILE)]] && echo "CSV file missing!"
  then return
fi

#check if tennant "openstack" exist

if [[ ! ($(keystone tenant-list | grep openstack))]] 
  then
    echo "Creating tenant:" $TENANT
    (keystone tenant-create --name=$TENANT --description='Tenant created by script')
  else
    echo "Tenant $TENANT already exist"
fi

OLDIFS=$IFS
IFS=$','
while read user_name user_id user_email
 do
  if [[ ! ($(keystone user-list | grep $user_id))]]
    then
      password=$(pass_create)
      echo "Adding u:$user_id p:$password to tenant: $TENANT"
      tenant_id=$(keystone tenant-list | grep $TENANT | awk '{print $2}')
      echo "tenant_id:$tenant_id"
      echo "$user_name u:$user_id p:$passwd" >> created_user_accounts.txt
      (keystone user-create --name=$user_id --pass=$password --email=$user_email --tenant_id=$tenant_id)
   else
      echo "User $user_id already exist!"  
  fi
 done < $CSVFILE
IFS=$OLDIFS


