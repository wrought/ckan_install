#!/bin/bash

####################
# CKAN installation script
# based on http://docs.ckan.org/en/master/install-from-source.html
####################

# @TODO Get these values as flags
dbpassword='abcde12345'
readonlydbpassword='abcde12345'
jettyhost='localhost'
jettyport='8983'


####################
# install packages
####################
#apt-get install python-dev postgresql libpq-dev python-pip python-virtualenv git-core solr-jetty openjdk-6-jdk
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

# create postgres password file for createuser
echo "$dbpassword" > .pgpass
# add ckanuser
sudo -u postgres createuser -S -D -R -P ckanuser --no-password

# create postgres db
sudo -u postgres createdb -O ckanuser ckandb -E utf-8

####################
# CKAN config
####################
cd ~/pyenv/src/ckan
paster make-config ckan development.ini
# edit development.ini
sed -i "s/\(#\+\)\?\( \+\)\?sqlalchemy\.url\( \+\)\?=\( \+\)\?.*/sqlalchemy.url = postgresql:\/\/ckanuser:$dbpassword@localhost\/ckantest\//" development.ini

####################
# Jetty Config     #
####################
sed -i "s/\(#\+\)\?\( \+\)\?NO_START=.*/NO_START=0/" /etc/default/jetty
sed -i "s/\(#\+\)\?\( \+\)\?JETTY_HOST=.*/JETTY_HOST=$jettyhost/" /etc/default/jetty
sed -i "s/\(#\+\)\?\( \+\)\?JETTY_PORT=.*/JETTY_PORT=$jettyport/" /etc/default/jetty

sudo service jetty start
curl -N -s http://$jettyhost:$jettyport/solr/ | grep -i "Welcome to Solr" && jettycheck=$?
if [ ! $jettycheck ]
then
    echo "
Jetty is not running and accessible at http://$jettyhost:$jettyport/solr/
Please fix it and run this script again check if jetty knows where JDK is.
Read the comments of this install script for more info.
        "
    exit
fi

# If jetty can't find JDK, use correct path for "/usr/lib/..." such as below:
#
# sed -i s/"#\?JAVA_HOME=.*"/"/usr/lib/jvm/java-6-openjdk-amd64/"/ /etc/default/jetty
# sudo service jetty stop
# sudo service jetty start

# replace (link) solr config
sudo mv /etc/solr/conf/schema.xml /etc/solr/conf/schema.xml.bak
sudo ln -s ~/pyenv/src/ckan/ckan/config/solr/schema-2.0.xml /etc/solr/conf/schema.xml

sudo service jetty stop
sudo service jetty start

# config CKAN with solr settings
sed -i "s/ckan.site_id\( \+\)\?=\( \+\)\?.*/ckan.site_id = my_ckan_instance/"
	# @TODO wtf is this?
sed -i "s/solr_url\( \+\)\?=\( \+\)\?.*/solr_url = http:\/\/$jettyhost:$jettyport\/solr\//"


####################
# DB tables
####################

paster --plugin=ckan db init


####################
# Datastore
####################

# @TODO tack on to ckan.plugins, not simply replace
# sed -i s/'ckan.plugins = .*'/"datastore"/ development.ini

# Create read-only db user
sudo -u postgres createuser -S -D -R -P -l readonlyckanuser
# @TODO automate password prompt response
# expect "Enter password for new role:"
# send "$readonlydbpassword"

# Create datastore db
sudo -u postgres createdb -O ckanuser datastore -E utf-8

# Uncomment and update datastore config lines
sed -i s/'#\?ckan.datastore.write_url = .*'/"ckan.datastore.write_url = postgresql://ckanuser:$dbpassword/datastore"/ development.ini
sed -i s/'#\?ckan.datastore.read_url = .*'/"ckan.datastore.read_url = postgresql://readonlyckanuser:$readonlydbpassword/datastore"/ development.ini

# copy datastore permissions
paster datastore set-permissions postgres

# Run tests
#curl -X GET "http://127.0.0.1:5000/api/3/action/datastore_search?resource_id=_table_metadata"
#curl -X POST http://127.0.0.1:5000/api/3/action/datastore_create -H "Authorization: {YOUR-API-KEY}" -d '{"resource_id": "{RESOURCE-ID}", "fields": [ {"id": "a"}, {"id": "b"} ], "records": [ { "a": 1, "b": "xyz"}, {"a": 2, "b": "zzz"} ]}'
# Verify by browsing here: http://127.0.0.1:5000/api/3/action/datastore_search?resource_id={RESOURCE_ID}

# create data store dirs
mkdir data sstore

# @TODO is the who.ini file in same directory as CKAN config?


