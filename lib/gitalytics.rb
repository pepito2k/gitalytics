# encoding: UTF-8

require 'date'
require 'erb'
require 'digest/md5'

require 'gitlog'
require 'user'
require 'commit'

class Gitalytics

  VERSION = '1.1.1'

  def analyze(options)
    users = GitLog.parse_git_log

    case options[:format]
    when 'html'
      output_html_report(users)
    else
      output_cli_report(users)
    end
  end

  private

  def output_cli_report(users)
    users.each do |user|
      puts user.summary
    end
  end

  def output_html_report(users)
    template_file = File.read(File.join(File.dirname(__FILE__), "..", "assets", "gitalytics.html.erb"))
    erb = ERB.new(template_file)
    output_file = "gitalytics_result.html"
    File.open(output_file, 'w+') do |file|
      @users = users
      file.write(erb.result(binding))
    end
    host = RbConfig::CONFIG['host_os']
    if host =~ /mswin|mingw|cygwin/
      system "start #{output_file}"
    elsif host =~ /darwin/
      system "open #{output_file}"
    elsif host =~ /linux|bsd/
      system "xdg-open #{output_file}"
    end
  end

end
