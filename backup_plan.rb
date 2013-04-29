require 'rubygems'
require 'aws/s3'
require 'yaml'

module BackupPlan
  class Dumpfile
    def initialize(project = {}, options = {})
      @@project = project
      @@options = options
    end
  
    def database
      @database ||= YAML.load_file("#{@@project['base_path']}/config/database.yml")[@@project['env']]
    end
  
    def filename
      @filename ||= "#{database['database']}_#{Time.now.strftime('%F-%H.%M')}.backup"
    end
  
    def filename_path
      File.expand_path("/tmp/#{filename}", __FILE__)
    end
  
    def defaults
      { "user" => database['username'], 
        "password" => database['password'], 
        "result-file" => filename_path
      }
    end
  
    def options
      @@options.merge!(defaults)
    end
  
    def command
      options.map {|k,v| "--#{k}=#{v}"}.unshift("mysqldump")
    end
  
    def create!
      verbose!
      IO.popen(command + [database['database']]) { |file| puts file.gets }
      true
    end
  
    def clean!
      verbose!
      return self if File.delete("#{filename_path}") == 1
    end
    
    protected
    
    def describable(method_name)
      ["clean!", "create!"].include?(method_name)
    end
    
    def verbose?
      !!options["verbose"]
    end
    
    def verbose!
      calling_method = caller[0][/`([^']*)'/, 1]
      send("describe_#{calling_method}") if describable calling_method and verbose?
    end
    
    def describe_clean!
      puts "BackupPlan: Cleaning up dumpfile..."
    end
    
    def describe_create!
      puts "BackupPlan: Creating a dump of database data..."
    end
    
    private :options, :command, :defaults, :database
  end

  class Transfer
    def initialize(options = {}, verbose = false)
      @@amazon = options
      @verbose = verbose
      establish_connection!
    end
  
    def establish_connection!
      AWS::S3::Base.establish_connection!(
          :access_key_id     => @@amazon['access_key_id'],
          :secret_access_key => @@amazon['secret_access_key']
        )
    end
  
    def send!(dumpfile)
      verbose!
      raise TypeError, "Dumpfile argument expected" if not dumpfile.is_a? Dumpfile
      s3_object = AWS::S3::S3Object.store("#{dumpfile.filename}", open(dumpfile.filename_path), @@amazon['bucket'])
      s3_object.response.code == "200"
    end
  
    private :establish_connection!
    
    def verbose!
      puts "BackupPlan: Sending backup to Amazon S3..." unless not @verbose
    end
  end


  class Backup
    CONFIG = YAML.load_file(File.expand_path("../config.yml", __FILE__))
    @@project, @@amazon = CONFIG["project"], CONFIG["amazon"]
  
    def initialize(*args)
      @dump ||= Dumpfile.new(@@project, options)
      @amazon ||= Transfer.new(@@amazon, !!options['verbose'])
    end

    def options
      CONFIG['options'] || {}
    end
  
    def perform!
      @dump.clean! if @dump.create! and @amazon.send!(@dump)
    end
  
    private :options
  end
end

backup = BackupPlan::Backup.new
backup.perform!
