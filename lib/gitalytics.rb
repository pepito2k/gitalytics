# encoding: UTF-8

require 'haml'
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
    dir           = File.dirname(__FILE__)
    filepath      = File.join(dir, '..', 'assets', 'gitalytics.html.haml')
    template_file = File.read(filepath)
    output_file   = 'gitalytics_result.html'
    File.open(output_file, 'w+') do |file|
      @users = data[:users].sort do |x, y|
        y.commits.length <=> x.commits.length
      end
      @commits = data[:commits]
      weekday_commits = @users.map(&:weekday_commits)
      @weekday_commits = weekday_commits.map { |a| Vector[*a] }.inject(:+).to_a

      html = Haml::Engine.new(template_file).render(self)
      file.write(html)
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
