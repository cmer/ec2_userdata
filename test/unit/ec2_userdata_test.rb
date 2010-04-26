require 'rubygems'
require 'redgreen'
require 'test/unit'
require 'mocha'
require File.dirname(__FILE__) + '/../../lib/ec2_userdata'

APP_ROOT = "File.dirname(__FILE__) + '/../.."

class Ec2UserDataTest < Test::Unit::TestCase
  def setup
    EC2::UserData.class_eval("@userdata = nil")
    EC2::module_eval("@running_on_ec2 = nil")

  end
  
  def test_get_on_ec2
    EC2.expects(:ec2?).once.returns(true)
    Net::HTTP.expects(:get).with(URI.parse("http://169.254.169.254/1.0/user-data")).returns(ec2_json_userdata)
    
    assert_equal "lisa", EC2::UserData["cluster"]
    assert_equal 11300, EC2::UserData["queue_port"]
  end
  
  def test_get_on_local
    EC2.expects(:ec2?).once.returns(false)
    YAML.expects(:load_file).with("#{APP_ROOT}/config/ec2_userdata.yml").returns(YAML.load(local_yaml_userdata))
    assert_equal "lisa", EC2::UserData["cluster"]
    assert_equal 11300, EC2::UserData["queue_port"]
  end
  
  def test_ec2_true
    # Yes, on EC2
    EC2.expects(:cmd_exec).with("which nslookup").returns("/usr/bin/nslookup")
    EC2.expects(:cmd_exec).with("nslookup 169.254.169.254").returns(nslookup_on_ec2)
    assert EC2.ec2?
  end
  
  def test_ec2_false
    # No, not on EC2
    EC2.expects(:cmd_exec).with("which nslookup").returns("/usr/bin/nslookup")
    EC2.expects(:cmd_exec).with("nslookup 169.254.169.254").returns(nslookup_on_local)
    assert_equal false, EC2.ec2?
  end

  def test_ec2_ns_lookup_not_found
    # nslookup not found
    EC2.expects(:cmd_exec).with("which nslookup").returns("")
    assert_raises(RuntimeError) { EC2.ec2? }
  end


  ## Helpers ##
  def ec2_json_userdata
    '{"queue_host":"lisa-queue.defensio.net","cluster":"lisa","queue_port":11300}'
  end
  
  def local_yaml_userdata
    "--- \nqueue_host: lisa-queue.defensio.net\nqueue_port: 11300\ncluster: lisa\n"
  end
  
  def nslookup_on_ec2
    "Server:		172.16.0.23\nAddress:	172.16.0.23#53\n\nNon-authoritative answer:\n254.169.254.169.in-addr.arpa	name = instance-data.ec2.internal.\n\nAuthoritative answers can be found from:\n"
  end
  
  def nslookup_on_local
    "Server:		192.168.1.1\nAddress:	192.168.1.1#53\n\n** server can't find 254.169.254.169.in-addr.arpa.: NXDOMAIN\n"
  end
end