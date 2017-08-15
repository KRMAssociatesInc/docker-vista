#!/usr/bin/env bash
#---------------------------------------------------------------------------
# Copyright 2017 KRM Associates, Inc.
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

# Script to install Panorama

# Ensure presence of required variables
if [[ -z $instance && $gtmver && $gtm_dist && $basedir ]]; then
    echo "The required variables are not set (instance, gtmver, gtm_dist)"
fi

echo "Installing Panorama"

# Overwrite the config to add Panorama routes
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

var routes = [{
  path: '/ewd-vista-pushdata',
  module: 'ewd-vista-push-handler'
}]

var qewd = require('qewd').master;
qewd.start(config, routes);
EOF

# Install published modules
cd $basedir/qewd/node_modules
su $instance -c "source $basedir/etc/env && git clone https://github.com/shabiel/ewd-vista.git"
cd ewd-vista
su $instance -c "source $basedir/.nvm/nvm.sh && source $basedir/etc/env && npm install --quiet >> $basedir/log/ewd-vistaInstall.log"
cd ..
su $instance -c "source $basedir/etc/env && git clone https://github.com/shabiel/ewd-vista-login.git"
su $instance -c "source $basedir/etc/env && git clone https://github.com/shabiel/ewd-vista-bedboard.git"
su $instance -c "source $basedir/etc/env && git clone https://github.com/shabiel/ewd-vista-taskman-monitor.git"
su $instance -c "source $basedir/etc/env && git clone https://github.com/shabiel/ewd-vista-fileman.git"
su $instance -c "source $basedir/etc/env && git clone https://github.com/shabiel/ewd-vista-pharmacy.git"
su $instance -c "source $basedir/etc/env && git clone https://github.com/shabiel/ewd-vista-push-handler.git"
su $instance -c "source $basedir/etc/env && mkdir $basedir/qewd/www/ewd-vista"
su $instance -c "source $basedir/etc/env && cp -R $basedir/qewd/node_modules/ewd-vista/www/* $basedir/qewd/www/ewd-vista/"
