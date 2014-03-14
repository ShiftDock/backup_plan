Backup Plan
===========

Super simple Ruby script to back up your Rails MySQL database to Amazon S3.

There are a lot of libraries, gems and scripts out there that'll back up your database. Most of them are
overkill; being able to back up tons of different database types to a multitude of places. We just wanted
something quick and easy for our most common use case, MySQL to Amazon S3. So here it is.

Backup Plan requires an account with Amazon's S3 service. Sign up and create a bucket for your database backups
[here](http://aws.amazon.com/s3/), then generate an Access Key ID and Secret Access Key. Backup Plan parses your
project's `database.yml` file to get the information needed to back up your chosen database to S3.


## Installation

Requires the Amazon S3 gem:

    gem install aws-s3

Then simply clone this repo to any of your app servers:

    git clone git://github.com/ShiftDock/backup_plan.git

Edit the `config_example.yml` file with your project and Amazon S3 deets and any further options you want then rename it
to `config.yml` before running the script.

**Note**: You can run the script from any server with access to your database
server and copy of your rails app.

## Usage

    ruby backup_plan.rb

You'll probably want to run it regularly in a Cron job. This is usually as simple as opening Crontab with `crontab -e`
and adding a line like this:

    00 15 * * * ruby ~/scripts/backup_plan/backup_plan.rb

This will backup your database at 3pm daily.

### RVM Gotcha

The RVM site has good documentation on [how to use it with Cron](https://rvm.io/integration/cron); but usually it's
as simple as being explicit about the RVM wrapper for the Ruby and Gemset you want to use:

    00 15 * * * $rvm_path/wrappers/<ruby-version>[@gemset-name] ~/scripts/backup_plan/backup_plan.rb



### Non-Rails Projects

You can edit the `config.yml` and point the `base_path` at any folder with a
`config/database.yml` file that resembles a Rails one.

You can take advantage of this to backup any MySQL database you like by _faking_ a `database.yml`
in a `config` directory of the `backup_plan` root:

```
production:
    adapter: mysql2
    database: my_database
    username: my_name
    password: bigpassword!
    host: 127.0.0.1
    port: 3306

```

Then point the `base_url` in your `config.yml` file at the backup_plan folder like so:

```yaml
# Add the absolute path to your project and the environment of the database you want to back up.
project:
  base_path: /home/me/backup_plan
  env: production
```

## Customisation

The `config_example.yml` file is well annotated and allows you to not only set the required options; such as amazon
credentials and your project details, but to customise the behaviour of the script. Remember to rename it to `config.yml`.

Add an `options` entry if one doesn't exist and you can add any options that `mysqldump` normally takes (see [here](http://dev.mysql.com/doc/refman/5.1/en/mysqldump.html)),
allowing you full control over what kind of dumps you want to make of your database. If you chose verbosity or debugging
information Backup Plan will print this as it performs the dump. This will end up in your Cron logs and emails. Handy.

For safety you should be careful about allowing access to this config file. Certain options used internally by the script;
for example user, password and result-file, cannot be overridden in this way.
