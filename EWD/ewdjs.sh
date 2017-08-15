#!/usr/bin/env bash
#---------------------------------------------------------------------------
# Copyright 2011-2014 The Open Source Electronic Health Record Agent
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#---------------------------------------------------------------------------

# Script to install QEWD

# Ensure presence of required variables
if [[ -z $instance && $gtmver && $gtm_dist && $basedir ]]; then
    echo "The required variables are not set (instance, gtmver, gtm_dist)"
fi

# Options
# instance = name of instance
# used http://rsalveti.wordpress.com/2007/04/03/bash-parsing-arguments-with-getopts/
# for guidance

usage()
{
    cat << EOF
    usage: $0 options

    This script will automatically install EWD.js for GT.M

    DEFAULTS:
      Node Version = Latest 6.x

    OPTIONS:
      -h    Show this message
      -v    Node Version to install
      -f    Skip setting firewall rules

EOF
}

while getopts ":hfv:" option
do
    case $option in
        h)
            usage
            exit 1
            ;;
        f)
            firewall=false
            ;;
        v)
            nodever=$OPTARG
            ;;
    esac
done

# Set defaults for options
if [ -z $nodever ]; then
    nodever="6"
fi

if [[ -z $firewall ]]; then
    firewall=true
fi

echo "nodever $nodever"

# Set the node version
shortnodever=$(echo $nodever | cut -d'.' -f 2)

# set the arch
arch=$(uname -m | tr -d _)

# This should be ran as the instance owner to keep all of VistA together
if [[ -z $basedir ]]; then
    echo "The required variable \$instance is not set"
fi

echo "Installing QEWD"

# Copy init.d scripts to VistA etc directory
su $instance -c "cp -R etc $basedir"

# Download installer in tmp directory
cd $basedir/tmp

# Install node.js using NVM (node version manager)
echo "Downloading NVM installer"
curl -s -k --remote-name -L  https://raw.githubusercontent.com/creationix/nvm/master/install.sh
echo "Done downloading NVM installer"

# Execute it
chmod +x install.sh
su $instance -c "./install.sh"

# Remove it
rm -f ./install.sh

# move to $basedir
cd $basedir

# Install node
su $instance -c "source $basedir/.nvm/nvm.sh && nvm install $nodever && nvm alias default $nodever && nvm use default"

# Tell $basedir/etc/env our nodever
echo "export nodever=$nodever" >> $basedir/etc/env

# Tell nvm to use the node version in .profile or .bash_profile
if [ -s $basedir/.profile ]; then
    echo "source \$HOME/.nvm/nvm.sh" >> $basedir/.profile
    echo "nvm use $nodever" >> $basedir/.profile
fi

if [ -s $basedir/.bash_profile ]; then
    echo "source \$HOME/.nvm/nvm.sh" >> $basedir/.bash_profile
    echo "nvm use $nodever" >> $basedir/.bash_profile
fi

# Create directories for node
su $instance -c "source $basedir/etc/env && mkdir $basedir/qewd"

# Install required node modules
cd $basedir/qewd
su $instance -c "source $basedir/.nvm/nvm.sh && source $basedir/etc/env && nvm use $nodever && npm install --quiet nodem >> $basedir/log/nodemInstall.log"
su $instance -c "source $basedir/.nvm/nvm.sh && source $basedir/etc/env && nvm use $nodever && npm install --quiet qewd >> $basedir/log/qewdInstall.log"
su $instance -c "source $basedir/.nvm/nvm.sh && source $basedir/etc/env && nvm use $nodever && npm install --quiet qewd-monitor >> $basedir/log/qewdMonitorInstall.log"

# Copy any routines in qewd
su $instance -c "find $basedir/qewd -name \"*.m\" -type f -exec cp {} $basedir/p/ \;"
su $instance -c "cd $basedir/p && dos2unix *.m"

# Copy webserver files to where they belong
su $instance -c "source $basedir/etc/env && mkdir -p www/qewd-monitor"
su $instance -c "source $basedir/etc/env && cp $basedir/qewd/node_modules/qewd-monitor/www/* $basedir/qewd/www/qewd-monitor/"

# Setup GTM C Callin
calltab=$(ls -1 $basedir/qewd/node_modules/nodem/resources/*.ci)
echo "export GTMCI=$calltab" >> $basedir/etc/env

# Create qewd config
cat > $basedir/qewd/qewd.js << EOF
var config = {
  managementPassword: 'keepThisSecret!',
  serverName: '${instance} QEWD Server',
  port: 8080,
  poolSize: 5,
  database: {
    type: 'gtm'
  }
};

var qewd = require('qewd').master;
qewd.start(config);
EOF

# Ensure correct permissions
chown $instance:$instance $basedir/qewd/qewd.js

# Modify init.d scripts to reflect $instance
perl -pi -e 's#/home/foia#'$basedir'#g' $basedir/etc/init.d/qewd

# Create startup service
ln -s $basedir/etc/init.d/qewd /etc/init.d/${instance}vista-qewd

# Install init script
if [[ $ubuntu || -z $RHEL ]]; then
    update-rc.d ${instance}vista-qewd defaults
fi

if [[ $RHEL || -z $ubuntu ]]; then
    chkconfig --add ${instance}vista-qewd
fi

# Add firewall rules
if $firewall; then
    if [[ $RHEL || -z $ubuntu ]]; then
        sudo iptables -I INPUT 1 -p tcp --dport 8080 -j ACCEPT # EWD.js

        sudo service iptables save
    fi
fi

echo "Done installing qewd"
