require 'rubygems'
require 'aws/s3'
require 'yaml'

config = YAML.load_file(File.expand_path("../config.yml", __FILE__))
project, amazon = config["project"], config["amazon"]

AWS::S3::Base.establish_connection!(
    :access_key_id     => amazon['access_key_id'],
    :secret_access_key => amazon['secret_access_key']
  )
  
database = YAML.load_file("#{project['base_path']}/config/database.yml")[project['env']]

filename = "#{database['database']}_#{Time.now.strftime('%F-%H.%M')}.backup"
dumpfile = File.expand_path("/tmp/#{filename}", __FILE__)

print "Creating dumpfile (#{filename})..."

defaults = {
  "user" => database['username'],
  "password" => database['password'],
  "result-file" => dumpfile
}

options = config['options'] || {}
options.merge!(defaults)

command = options.map {|k,v| "--#{k}=#{v}"}
command.unshift("mysqldump")

IO.popen(command + [database['database']]) { |file| puts file.gets }

puts "done."

print "Sending backup to AWS..."
s3_object = AWS::S3::S3Object.store("#{filename}", open(dumpfile), amazon['bucket'])

puts "done."

if s3_object.response.code == "200"
  puts "Dumpfile deleted." if File.delete("#{dumpfile}") == 1
else
  puts "WARNING: Dumpfile not deleted."
end