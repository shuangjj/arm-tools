#!/bin/bash

#-------------------------------------------------------------------------------
# Print usage
#-------------------------------------------------------------------------------
usage() {
  printf "abolishpi {user} {passwd}\n"
  printf "%-20s%-10s%s\n" "--override" "-o" "Remove {user} account if it exists."
}

username=$1
passwd=$2
if [ -z $username ] || [ -z $passwd ]
then
  echo 
  usage
  echo
  exit -1
fi

# -$- Create new user account
machines=$(docker-machine ls | awk 'NR > 1  {print $1}')
for machine in $machines
do
  printf "\nOn machine: $machine\n"
  if [ "$(docker-machine ssh $machine whoami)" = $username ]; then
    echo "You're $username, bye!"
    if [ "docker-machine ssh $machine getent passwd pi > /dev/null" ]
    then
      docker-machine ssh $machine sudo userdel -r pi
      echo "pi deleted!"
    fi
    continue
  fi

  # TODO: support --override
  if [ "docker-machine ssh $machine getent passwd $username > /dev/null" ]
  then
    echo "Deleting existing $username account..."
    docker-machine ssh $machine "echo raspberry | sudo -S userdel -r $username 2&>/dev/null" &>/dev/null
  fi
   
  echo "Creating $username..."
  docker-machine ssh $machine "echo raspberry | sudo -S useradd -m -s /bin/bash $username &>/dev/null && \
    echo $username:$passwd | sudo chpasswd" &>/dev/null

  # -$- Change hostname -$-
  if false; then
    oldname=`hostname`
    docker-machine ssh $machine "sudo sed -i 's/\b$oldname\b/$machine/' /etc/hostname"
    docker-machine ssh $machine "sudo sed -i 's/\b$oldname\b/$machine/' /etc/hosts"
    docker-machine ssh $machine "sudo /etc/init.d/hostname.sh start"
  fi

  # -$- Remove pi from sudoer -$-  
  docker-machine ssh $machine "echo raspberry | sudo -S sed -i 's/\bpi\b/$username/' /etc/sudoers &>/dev/null" &>/dev/null
done

echo 
echo "Finished!"
exit 0




