Backup Plan
===========

Super simple Ruby script to back up your Rails MySQL database to Amazon S3.

There are a lot of libraries, gems and scripts out there that'll back up your database. Most of them are
overkill; being able to back up tons of different database types to a multitude of places. We just wanted
something quick and easy for our most common use case, MySQL to Amazon S3. So here it is.

## Installation

Requires the Amazon S3 gem to work.

    gem install aws-s3

Then simply copy the directory to your server and create/edit the config.yml file with your project and Amazon S3 deets.

## Usage

    ruby db_backup.rb

You'll probably want to run it regularly in a Cron job. This is usually as simple as opening Crontab with `crontab -e`
and adding a line like this:

    00 15 * * * ruby ~/scripts/backup_plan/db_backup.rb

This will backup your database at 3pm daily.

## RVM Gotcha

You didn't think it'd be that simple did you? Well it is... almost. There's a slight problem if you're managing your Rubies
with RVM in that the shell used by Cron might use the wrong ruby and thus the wrong gemset.

It's easily fixed though, you can simply put the path to the Ruby you want to use into the Crontab file.

    00 15 * * * /home/me/.rvm/bin/ruby-1.9.3-p125 ~/scripts/backup_plan/db_backup.rb

You can get the path by running `which rvm` and running `ls -al path` to get a list of the Rubies available to you.

Sweet.
