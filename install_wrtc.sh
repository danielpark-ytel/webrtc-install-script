#!/bin/bash
# PROMPT USER FOR INSTALL CONFIRMATION #
echo "This will install the Message360 WebRTC client, configured for use with the PHP Helper LIbrary."
echo -n "Do you want to continue? Type yes or no and press [ENTER]: "
read choice
cancel_error="Installation cancelled, exiting install."
if [ $choice == 'yes' ]; then
    # DOWNLOAD WEBRTC SOURCE CODE AND MESSAGE360 HELPER LIBRARY #
    echo 'Performing install... Downloading source code.'
    git clone https://github.com/danielpark-ytel/message360-webrtc.git webrtc
    cd webrtc
    echo 'Downloading Message360 Helper Library PHP-V2'
    git clone https://github.com/mgrofsky/message360-API-V2-PHP.git m360-php
    cd m360-php
    # MAKE SCRIPTS DIRECTORY AND CREATE HELPER LIBRARY FILES #
    mkdir scripts
    cd scripts
    touch accessToken.php authenticateNumber.php checkFunds.php
    cd ../
    # CHECK FOR COMPOSER INSTALL AND INSTALL IF MISSING, RUN COMPOSER #
    command -v composer >/dev/null && echo "Composer is already installed." && composer install || { 
        echo -n 'Composer was not found and is required, do you want to install? [yes/no]: '
        read choice
        if [ $choice == 'yes' ]; then
            echo 'Installing Composer...'
            curl -LOk https://getcomposer.org/installer composer-setup.php
            php -r "if (hash_file('SHA384', 'composer-setup.php') === 'aa96f26c2b67226a324c27919f1eb05f21c248b987e6195cad9690d5c1ff713d53020a02ac8c217dbf90a7eacc9d141d') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;"
            php composer-setup.php
            php -r "unlink('composer-setup.php')"
            mv composer.phar composer
            echo 'Composer installed successfully.'
            composer install
        else
            if [ $choice == 'no' ]; then
                echo $cancel_error
                exit 1
            fi
        fi
    }
    # PROMPT FOR SID AND TOKEN #
    echo -n "Enter your Message360 Account SID (Please make sure there are no spaces or extra characters): "
    read account_sid
    while [ ${#account_sid} -ne 36 ]; do
        echo -n "Not a valid Account SID. Your Account SID should be 36 characters in length. Please try again: "
        read account_sid
    done
    echo -n "Enter your Message360 Auth Token (Please make sure there are no spaces or extra characters): "
    read auth_token
    while [ ${#auth_token} -ne 32 ]; do 
        echo -n "Not a valid Auth Token. Your Auth Token should be 32 characters in length. Please try again: "
        read auth_token
    done
    # PRINT REQUIRED PHP CODE TO HELPER LIBRARY FILES #
    echo 'Configuring Helper Library files for usage.'
    cd scripts 
    # PHP code for accessToken.php #
    echo "
    <?php
    require_once '../vendor/autoload.php';
    require_once '../'
    \$client = new Message360Lib\Message360Client('$account_sid','$auth_token');
    \$wrtc = \$client->getWebRTC();
    \$collect['accountSid'] = '$account_sid';
    \$collect['authToken'] = '$auth_token';
    \$result = \$wrtc->getToken(\$collect);
    echo json_encode(\$result);" >> accessToken.php
    # PHP code for checkFunds.php #
    echo "
    <?php
    require_once '../vendor/autoload.php';
    \$client = new Message360Lib\Message360Client('$account_sid','$auth_token');
    \$wrtc = \$client->getWebRTC();
    \$collect['accountSid'] = '$account_sid';
    \$collect['authToken'] = '$auth_token';
    \$result = \$wrtc->createCheckFunds(\$collect);
    echo json_encode(\$result);" >> checkFunds.php
    # PHP code for authenticateNumber.php #
    echo "
    <?php
    require_once '../vendor/autoload.php';
    \$client = new Message360Lib\Message360Client('$account_sid','$auth_token');
    \$wrtc = \$client->getWebRTC();
    \$collect['accountSid'] = '$account_sid';
    \$collect['authToken'] = '$auth_token';
    \$input = file_get_contents('php://input');
    \$request = json_decode(\$input);
    \$phone_number = \$request->phone_number;
    \$collect['phoneNumber'] = \$phone_number;
    \$result = \$wrtc->createCheckFunds(\$collect);
    echo json_encode(\$result);" >> authenticateNumber.php
    # ADD PHP URL'S TO APP SOURCE CODE #
    sed -ie "s/\$rootScope\.tokenUrl = '';/\$rootScope\.tokenUrl = 'm360-php\/scripts\/accessToken\.php';/g" ./../../src/js/verto.module.js
    sed -ie "s/\$rootScope\.fundUrl = '';/\$rootScope\.fundUrl = 'm360-php\/scripts\/checkFunds\.php';/g" ./../../src/js/verto.module.js
    sed -ie "s/\$rootScope\.numberUrl = '';/\$rootScope\.numberUrl = 'm360-php\/scripts\/authenticateNumber\.php';/g" ./../../src/js/verto.module.js
    # TEMPORARY: CHANGE CONFIG ENVIRONMENT TO DEVELOPMENT #
    sed -ie 's/public static \$environment = Environments::PRODUCTION/public static \$environment = Environments::PREPRODUCTION/g' ./../src/Configuration.php
    cd ../../;
    command -v node >/dev/null && echo "Node.js is already installed, checking for updates.." && npm install npm@latest -g || { 
        echo -n 'Node.js was not found and is required, do you want to install? [yes/no]: '
        read choice
        if [ $choice == 'yes' ]; then
            # DETECT OS FOR NODE.JS INSTALL #
            cwd=$(pwd)
            case $OSTYPE in
                darwin*) cd /tmp && wget http://nodejs.org/dist/v6.3.1/node-v6.3.1-darwin-x86.tar.gz && tar xvfz node-v6.3.1-darwin-x64.tar.gz && mkdir -p /usr/local/nodejs && mv node-v6.3.1-darwin-x86/* /usr/local/nodejs && export PATH=$PATH:/usr/local/nodejs/bin ;;
                linux*) cd /tmp && wget http://nodejs.org/dist/v6.3.1/node-v6.3.1-linux-x86.tar.gz && tar xvfz node-v6.3.1-linux-x64.tar.gz && mkdir -p /usr/local/nodejs && mv node-v6.3.1-darwin-x86/* /usr/local/nodejs && export PATH=$PATH:/usr/local/nodejs/bin ;;
                *) OS="Error installing Node.js, if are on a Windows Operating System please visit the Node.js website, follow instructions, and try again." && exit 1 ;;
            esac
            npm install npm@latest -g
            cd $cwd
        else
            if [ $choice == 'no' ]; then
                echo $cancel_error
                cd ../ && rm -rf webrtc
                exit 1
            fi
        fi
    }
    # INSTALL BOWER IF NOT INSTALLED #
    command -v bower >/dev/null && echo "Bower is installed, continuing with build." || {
        echo -n "Bower was not found and is required, do you want to install? [yes/no]: "
        read choice
        if [ $choice == 'yes' ]; then
            npm install -g bower
        else 
            if [ $choice == 'no' ]; then
                echo $cancel_error
                exit 1
            fi
        fi
    }
    # RUN NPM INSTALL AND BOWER INSTALL #
    npm install && bower install
    # RUN GRUNTFILE.JS #
    grunt
else
    if [ $choice == 'no' ]; then
        echo $cancel_error
        exit 1
    fi
fi