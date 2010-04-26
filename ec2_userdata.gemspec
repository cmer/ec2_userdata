spec = Gem::Specification.new do |s|
  s.name = 'ec2_userdata'
  s.version = '1.0'
  s.summary = "A simple Ruby library that reads UserData on EC2 with graceful fallback when not running on EC2"
  s.description = %{A simple Ruby library that reads UserData on EC2 with graceful fallback when not running on EC2}
  s.files = Dir['lib/**/*.rb'] + Dir['test/**/*.rb']
  s.require_path = 'lib'
  s.has_rdoc = false
  s.author = "Carl Mercier"
  s.email = "carl@carlmercier.com"
  s.homepage = "http://carlmercier.com"
end