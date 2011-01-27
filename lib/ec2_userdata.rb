require 'net/http'
require 'json/pure' unless defined?(JSON)
require 'yaml' unless defined?(YAML)
require 'resolv' unless defined?(Resolv)

module EC2
  class UserData
    def self.[](key)
      unless defined?(@userdata)
        if EC2.ec2? && !use_local_config?
          logger.info "Running on EC2. Reading user data from http://169.254.169.254/1.0/user-data" if logger
          @userdata = get_ec2_userdata
        else
          logger.info "Reading user data from #{app_root}/config/ec2_userdata.yml." if logger
          @userdata = get_local_userdata
        end
      end

      @userdata[key]
    end

    # Force use of local configuration file even when running on EC2
    def self.use_local_config!
      @use_local_config = true
    end

    def self.use_local_config?
      @use_local_config == true
    end

    private
    def self.get_ec2_userdata
      JSON.parse(Net::HTTP.get(URI.parse("http://169.254.169.254/1.0/user-data")))
    end

    def self.get_local_userdata
      if app_root
        YAML.load_file("#{app_root}/config/ec2_userdata.yml")
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
        if Rails.respond_to?(:root)
          Rails.root
        else
          RAILS_ROOT
        end

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
    return @running_on_ec2 if defined?(@running_on_ec2)

    begin
      @running_on_ec2 = Resolv.getname("169.254.169.254").include?(".ec2.internal")
    rescue Resolv::ResolvError
      @running_on_ec2 = false
    end

    @running_on_ec2
  end
end
