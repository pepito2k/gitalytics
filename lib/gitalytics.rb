# encoding: UTF-8

require 'gitalytics/commit'
require 'gitalytics/gitlog'
require 'gitalytics/report'
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

  def repo_name
    top = `git rev-parse --show-toplevel 2>/dev/null`.strip
    File.basename(top.empty? ? Dir.pwd : top)
  end

  def output_html_report(data, open_in_browser)
    report = Report.new(users: data[:users], commits: data[:commits], repo_name: repo_name)
    File.write(OUTPUT_FILE, report.render)
    puts "Report written to #{File.expand_path(OUTPUT_FILE)}"
    open_report_in_browser if open_in_browser
  end

  def open_report_in_browser
    case RbConfig::CONFIG['host_os']
    when /mswin|mingw|cygwin/
      system "start #{OUTPUT_FILE}"
    when /darwin/
      system "open #{OUTPUT_FILE}"
    when /linux|bsd/
      system "xdg-open #{OUTPUT_FILE}"
    end
  end
end
