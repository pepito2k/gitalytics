# encoding: UTF-8

require 'erb'
require 'matrix'
require 'gitalytics/commit'
require 'gitalytics/gitlog'
require 'gitalytics/user'
require 'gitalytics/version'

module Gitalytics
  module_function

  def analyze(options)
    data = GitLog.parse_git_log(options[:group_by])

    case options[:format]
    when 'html'
      output_html_report(data, options[:browser])
    else
      output_cli_report(data[:users])
    end
  end

  private

  module_function

  def output_cli_report(users)
    users.each do |user|
      puts user.summary
    end
  end

  def output_html_report(data, open_in_browser)
    template_file = File.read(File.join(File.dirname(__FILE__), '..', 'assets', 'gitalytics.html.erb'))
    erb = ERB.new(template_file)
    output_file = 'gitalytics_result.html'
    File.open(output_file, 'w+') do |file|
      @users = data[:users].sort do |x, y|
        y.commits.length <=> x.commits.length
      end
      @commits = data[:commits]
      weekday_commits = @users.map(&:weekday_commits)
      @weekday_commits = weekday_commits.map { |a| Vector[*a] }.inject(:+).to_a

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
