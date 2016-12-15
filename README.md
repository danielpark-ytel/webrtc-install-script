# WebRTC Installation Script
### For use with the PHP Helper Library V2


## Overview

This is the script that will do all the manual labor for the WebRTC platform install.
Bear in mind this is for the browser platform configured with the <b>PHP Helper Library V2</b>


### Installation Information

This script will do a number of things

* Download WebRTC Platform Repository

* Download PHP Helper Library V2

* Check for Composer as the PHP Helper Library is dependent on it and install if missing

* Prompt for Message360 Account SID and Auth Token

* Create and configure three PHP scripts in the Helper Library for usage with WebRTC
    1. accessToken.php
    2. checkFunds.php
    3. authenticateNumber.php
    
* Write the necessary Account SID and Auth Token parameters for the three PHP scripts (This way the customer does not have to configure his/her own scripts.)

* UNTIL DEVELOPMENT ONLY: Using `sed`, change the environment variable to `public static $environment = Environments::DEVELOPMENT` in Helper Library's Configuration.php file

* Using `sed`, edit the WebRTC client's `verto.module.js` and replace the url's that the application has to hit for the Helper Library scripts that were generated.
    1. `$rootScope.tokenUrl = '';` => `$rootScope.tokenUrl = 'path/to/generatedFile.php';`
    2. `$rootScope.fundsUrl = '';` => `$rootScope.fundsUrl = 'path/to/generatedFile.php';`
    3. `$rootScope.numberUrl = '';` => `$rootScope.numberUrl = 'path/to/generatedFile.php';`

* Check for Node.js and Bower as the WebRTC client source code is dependent on NPM and Bower, install if missing

* Run a `npm install` to install Grunt from `package.json` file

* Run a `bower install` to install all packages and libraries for WebRTC source code

* Run a `grunt` to do certain minify, concat, etc., all necessary files so it's automatically ready for deployment


    