# encoding: UTF-8

require 'date'
require 'erb'
require 'digest/md5'

class Gitalytics

  VERSION = '1.0.4'

  attr_accessor :data

  def initialize
    @data = {}
  end

  def analyze(options)
    log_to_hash
    case options[:format]
    when 'html'
      output_html_report
    else
      output_cli_report
    end
  end

  private
  def log_to_hash
    lines   = []
    command = "git log --pretty='%cn|%ce|%cd|%s' --reverse"
    result  = `#{command}`

    result.each_line do |line|
      parts = line.split('|')
      lines << { name: parts[0], email: parts[1], date: Date.parse(parts[2]), subject: parts[3]}
    end

    @data[:users] = get_user_data(lines)
  end

  def output_cli_report
    @data[:users].each do |user|
      puts "#{user[:name]} has made #{user[:commits].count} commits between #{(user[:last_date] - user[:first_date]).to_i + 1} days. He did something useful on #{user[:working_days]} of those days."
    end
  end

  def output_html_report
    template_file = File.read(File.join(File.dirname(__FILE__), "..", "assets", "gitalytics.html.erb"))
    erb = ERB.new(template_file)
    File.open("gitalytics_result.html", 'w+') { |file| file.write(erb.result(binding)) }
  end

  def get_user_data(lines)
    users = {}
    lines.each{ |r| users[r[:email]] = r[:name] }
    users.map{ |email, name|
      commits = lines.select{ |r| r[:email] == email }
      dates = commits.map{ |c| c[:date] }
      {
        name: name,
        email: email,
        gravatar: Digest::MD5.hexdigest(email),
        color: "%06x" % (rand * 0xffffff),
        commits: commits,
        first_date: dates.min,
        last_date: dates.max,
        working_days: dates.uniq.count
      }
    }
  end

end
