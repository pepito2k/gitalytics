Gem::Specification.new do |s|
  s.name        = "gitalytics"
  s.version     = "1.2.1"

  s.executables << "gitalytics"

  s.date        = "2014-01-18"
  s.summary     = "Git Analytics"
  s.description = "Get usefull analytics from your git log"
  s.authors     = ["Gonzalo Robaina"]
  s.email       = "gonzalor@gmail.com"

  s.files       = []
  s.files       << "lib/gitalytics.rb"
  s.files       << "lib/gitlog.rb"
  s.files       << "lib/user.rb"
  s.files       << "lib/commit.rb"
  s.files       << "assets/gitalytics.html.erb"

  s.homepage    = "http://rubygems.org/gems/gitalytics"
  s.license     = "MIT"
end
