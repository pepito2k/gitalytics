# encoding: UTF-8

require 'haml'
require 'matrix'
require 'gitalytics/commit'
require 'gitalytics/gitlog'
require 'gitalytics/user'
require 'gitalytics/version'

module Gitalytics
  OUTPUT_FILE = 'gitalytics_result.html'.freeze

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

  def prepare_data(data)
    @users = data[:users].sort { |x, y| y.commits.length <=> x.commits.length }
    @commits = data[:commits]
    weekday_commits = @users.map(&:weekday_commits)
    @weekday_commits = weekday_commits.map { |a| Vector[*a] }.inject(:+).to_a
  end

  def output_html_report(data, open_in_browser)
    dir           = File.dirname(__FILE__)
    filepath      = File.join(dir, '..', 'assets', 'gitalytics.html.haml')
    template_file = File.read(filepath)
    File.open(OUTPUT_FILE, 'w+') do |file|
      prepare_data(data)
      file.write(Haml::Engine.new(template_file).render(self))
    end
    open_report_in_browser(OUTPUT_FILE) if open_in_browser
  end

  def open_report_in_browser(filename)
    case RbConfig::CONFIG['host_os']
    when /mswin|mingw|cygwin/
      system "start #{filename}"
    when /darwin/
      system "open #{filename}"
    when /linux|bsd/
      system "xdg-open #{filename}"
    end
  end
end
