# encoding: UTF-8

require 'erb'
require 'gitlog'
require 'user'
require 'commit'

class Gitalytics

  VERSION = '1.2.0'

  def analyze(options)
    data = GitLog.parse_git_log

    case options[:format]
    when 'html'
      output_html_report(data, options[:browser])
    else
      output_cli_report(data[:users])
    end
  end

  private

  def output_cli_report(users)
    users.each do |user|
      puts user.summary
    end
  end

  def output_html_report(data, open_in_browser)
    template_file = File.read(File.join(File.dirname(__FILE__), "..", "assets", "gitalytics.html.erb"))
    erb = ERB.new(template_file)
    output_file = "gitalytics_result.html"
    File.open(output_file, 'w+') do |file|
      @users = data[:users]
      @commits = data[:commits]
      file.write(erb.result(binding))
    end
    open_report_in_browser(output_file) if open_in_browser
  end

  def open_report_in_browser(filename)
    host = RbConfig::CONFIG['host_os']
    if host =~ /mswin|mingw|cygwin/
      system "start #{filename}"
    elsif host =~ /darwin/
      system "open #{filename}"
    elsif host =~ /linux|bsd/
      system "xdg-open #{filename}"
    end
  end

end
