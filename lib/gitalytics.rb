# frozen_string_literal: true

require 'gitalytics/cli_report'
require 'gitalytics/commit'
require 'gitalytics/gitlog'
require 'gitalytics/json_report'
require 'gitalytics/report'
require 'gitalytics/user'
require 'gitalytics/version'

module Gitalytics
  OUTPUT_FILE = 'gitalytics_result.html'

  module_function

  def analyze(options)
    data = GitLog.parse_git_log(options[:group_by], since: options[:since], until_date: options[:until],
                                                    no_merges: options[:no_merges])

    case options[:format]
    when 'html'
      output_html_report(data, options)
    when 'json'
      puts JsonReport.new(build_report(data)).render
    else
      output_cli_report(data, options)
    end
  end

  def output_cli_report(data, options, io = $stdout)
    color = options.fetch(:color) { CliReport.color?(io) }
    io.print CliReport.new(build_report(data), color: color, width: CliReport.width_for(io),
                                               top: options.fetch(:top, CliReport::DEFAULT_TOP)).render
  end

  def repo_name
    top = `git rev-parse --show-toplevel 2>/dev/null`.strip
    File.basename(top.empty? ? Dir.pwd : top)
  end

  def build_report(data)
    Report.new(users: data[:users], commits: data[:commits], repo_name: repo_name)
  end

  def output_html_report(data, options)
    path = File.expand_path(options[:output] || OUTPUT_FILE)
    File.write(path, build_report(data).render)
    puts "Report written to #{path}"
    open_report_in_browser(path) if options[:browser]
  end

  def open_report_in_browser(path)
    command =
      case RbConfig::CONFIG['host_os']
      when /mswin|mingw|cygwin/ then %w[cmd /c start]
      when /darwin/ then ['open']
      when /linux|bsd/ then ['xdg-open']
      end
    system(*command, path) if command
  end
end
