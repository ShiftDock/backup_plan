require 'rubygems'
require 'aws/s3'
require 'yaml'

config = YAML.load_file(File.expand_path("../config.yml", __FILE__))
project_config, amazon_config = config["project"], config["amazon"]

AWS::S3::Base.establish_connection!(
    :access_key_id     => amazon_config['access_key_id'],
    :secret_access_key => amazon_config['secret_access_key']
  )
  
database = YAML.load_file("#{project_config['base_path']}/config/database.yml")[project_config['env']]
dumpfile = File.expand_path("/tmp/#{database['database']}_backup", __FILE__)

print "Creating dumpfile (#{dumpfile})..."
command = "mysqldump --user #{database['username']} --password=#{database['password']} #{database['database']} > #{dumpfile}"

r = system(command)
puts "done."

print "Sending backup to AWS..."
send = AWS::S3::S3Object.store("#{database['database']}_#{Time.now.strftime('%F-%H.%M')}.backup", open(dumpfile), amazon_config['bucket'])

puts "done."

if send.response.code == "200"
  puts "Dumpfile deleted." if File.delete("#{dumpfile}") == 1
else
  puts "WARNING: Dumpfile not deleted."
end