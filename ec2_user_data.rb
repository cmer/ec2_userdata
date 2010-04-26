require 'net/http'
require 'json/pure'

module EC2
  class UserData
    def self.[](key)
      if @user_data.nil?
        if EC2.ec2?
          logger.info "Running on EC2. Reading user data from http://169.254.169.254/1.0/user-data" if logger
          @user_data = get_ec2_user_data
        else
          logger.info "Not running on EC2. Reading user data from #{app_root}/config/ec2_user_data.yml." if logger
          @user_data = get_local_user_data
        end
      end

      @user_data[key]
    end
    
    private
    def self.get_ec2_user_data
      JSON.parse(Net::HTTP.get(URI.parse("http://169.254.169.254/1.0/user-data")))
    end
    
    def self.get_local_user_data
      if app_root
        YAML.load_file("#{app_root}/config/ec2_user_data.yml")
      else
        raise "Cannot find app_root. Don't know what to do!"
      end
    end
    
    def self.logger
      if defined?(Rails)
        Rails.logger
      elsif defined?(Merb)
        Merb.logger
      elsif defined?(LOGGER)
        LOGGER
      else
        nil
      end
    end
    
    def self.app_root
      if defined?(Rails)
        RAILS_ROOT
      elsif defined?(Merb)
        Merb.root
      elsif defined?(APP_ROOT)
        APP_ROOT
      else
        nil
      end
    end
  end

  # Returns true if the current instance is running on the EC2 cloud
  def self.ec2?
    return @running_on_ec2 if @running_on_ec2
    raise("nslookup must be in the path") if cmd_exec("which nslookup").blank?
    @running_on_ec2 = (cmd_exec("nslookup 169.254.169.254").match(/NXDOMAIN/) || []).size < 1 
  end

  private
  def self.cmd_exec(cmd)
    `#{cmd}`
  end
end

class String
  def blank?
    self.strip.length == 0
  end
end

class NilClass
  def blank?; true; end
end