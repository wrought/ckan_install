#!/bin/bash

# @TODO Get these values as flags 
dbpassword='abcde12345'

####################
# install packages
####################
sudo apt-get install python-dev postgresql libpq-dev python-pip python-virtualenv git-core solr-jetty openjdk-6-jdk
# @TODO include 'expect' package to automate responses in script

####################
# Python & CKAN
####################

# create a python virtual environment, activate it
virtualenv --no-site-packages ~/pyenv
. ~/pyenv/bin/activate

# install ckan source
pip install -e 'git+https://github.com/okfn/ckan.git@release-v2.0#egg=ckan'

# install python modules in virtual environment
pip install -r ~/pyenv/src/ckan/pip-requirements.txt

# de- and re-activate virtual environment
deactivate
. ~/pyenv/bin/activate

####################
# postgresql database
####################
# sudo -u postgres psql -l # use to check if other dbs are utf8

# add ckanuser
sudo -u postgres createuser -S -D -R -P ckanuser # will prompt for password
# @TODO automate password prompt response
# expect "Enter password for new role:"
# send "$dbpassword"

# create postgres db
sudo -u postgres createdb -O ckanuser ckandb -E utf-8

####################
# CKAN config
####################
cd ~/pyenv/src/ckan
paster make-config ckan development.ini
# edit development.ini
sed -i s/"sqlalchemy.url = postgresql://ckanuser:pass@localhost/ckandb"/"sqlalchemy.url = postgresql://ckanuser:$dbpassword@localhost/ckantest"/ development.ini

####################
# Jetty Config     #
####################
sed -i "s/#\?NO_START=.*/NO_START=0/"
sed -i "s/#\?JETTY_HOST=.*/JETTY_HOST=$jettyhost/"
sed -i "s/#\?JETTY_PORT=.*/JETTY_PORT=$jettyport/"

sudo service jetty start
curl -N -s http://$jettyhost:$jettyport/solr/ | grep -i "Welcome to Solr!"
if [ !$? ]
then
    echo "Jetty is not running on http://$jettyhost:$jettyport/solr/ please fix it and run this script again check if jetty knows where JDK is. Read the comments of this install script for more info"
    exit
fi

# If jetty can't find JDK, use correct path for "/usr/lib/..." such as below:
#
# sed -i s/"#\?JAVA_HOME=.*"/"/usr/lib/jvm/java-6-openjdk-amd64/"/ /etc/default/jetty
# sudo service jetty stop
# sudo service jetty start

# replace (link) solr config!
sudo mv /etc/solr/conf/schema.xml /etc/solr/conf/schema.xml.bak
sudo ln -s ~/pyenv/src/ckan/ckan/config/solr/schema-2.0.xml /etc/solr/conf/schema.xml

sudo service jetty stop
sudo service jetty start



