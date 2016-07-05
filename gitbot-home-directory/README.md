## Using the gitbot account on coldpress

This directory is meant to hold the contents of the `gitbot` home
directory so that it is under revision control and can be retrieved if
the `gitbot` home directory is removed.


## Setting it all up.

1. Copy step1-clone-website-repo.sh into the home directory /lhome/gitbot.

    This script will copy all files in this directory to the home directory and
    start the install process.


2. Create ssh keys and add them to github.umn.edu for the `robot007` user.

   https://help.github.com/articles/generating-an-ssh-key/


## Other.

1.  .bashrc

     Adds /lhome/gitbot/.gem/ruby/2.3.0/bin in your PATH,

     Sets PATH explicitly so it has no remnants from the account
     being logged in from .


     step1-clone-website-repo.sh


2.  % gem install --user-install bundler

    This will give a warning the something like /lhome/gitbot/.gem/ruby/2.3.0/bin is not in the gitbot $PATH.  If it isn't there then add it to .bashrc

    See that the current version is in `PATH` in `.bashrc`.


3.  `bundle install --path vendor/bundle`

    This doesn't work for me (EVW)...



