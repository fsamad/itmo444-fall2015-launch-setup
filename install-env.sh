#!/bin/bash

sudo apt-get -y update  
sudo apt-get install -y apache2 git   

git clone https://github.com/fsamad/itmo444-fall2015-app-setup.git

mv ./itmo444-fall2015-app-setup/images /var/www/html/images
mv ./itmo444-fall2015-app-setup/index.html /var/www/html
mv ./itmo444-fall2015-app-setup/page2.html /var/www/html


echo "Farah Abdul Samad" /tmp/hello.txt    
