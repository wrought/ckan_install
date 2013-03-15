#!/bin/bash

# @TODO Get these values as flags 
$dbpassword = 'abcde12345'
$

# install packages
sudo apt-get install python-dev postgresql libpq-dev python-pip python-virtualenv git-core solr-jetty openjdk-6-jdk expect

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

# postgresql

# sudo -u postgres psql -l # use to check if other dbs 

# add ckanuser for postgres db
sudo -u postgres createuser -S -D -R -P ckanuser # will prompt for password
# @TODO verify automation 
# Enter password for new role:
expect "Enter password for new role:"
send "$dbpassword"

# create postgres db
sudo -u postgres createdb -O ckanuser ckandb -E utf-8

# create CKAN config
cd ~/pyenv/src/ckan
paster make-config ckan development.ini
# @TODO need to edit development.ini
sed s/"sqlalchemy.url = postgresql://ckanuser:pass@localhost/ckandb"/"sqlalchemy.url = postgresql://ckanuser:pass@localhost/ckantest"/ <development.ini development.ini>
