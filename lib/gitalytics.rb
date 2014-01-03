require 'date'
require 'json'
require 'erb'
require 'digest/md5'

class Gitalytics

  VERSION = '1.0.0a'

  attr_accessor :data

  def initialize
    @data = {}
  end

  def analyze(options)
    log_to_hash
    case options[:format]
    when 'html'
      write_html_report
    else
      output_summary_report
    end
  end

  def log_to_hash
    lines   = []
    command = "git log --pretty='%cn|%ce|%cd|%s'"
    result  = `#{command}`

    result.each_line do |line|
      parts = line.split('|')
      lines << { name: parts[0], email: parts[1], date: Date.parse(parts[2]), subject: parts[3]}
    end

    @data[:users] = get_user_data(lines)

  end

  def output_summary_report #TODO: FIX THIS METHOD TO USE @data
    res[:users].each do |user|
      dates_for_user = res[:records].select{|r| r[:name] == user}.map{|r| r[:date]}
      commit_count   = dates_for_user.count
      date_count     = dates_for_user.uniq.count
      first_date     = dates_for_user.min
      last_date      = dates_for_user.max
      puts "#{user} has made #{commit_count} commits over the last #{last_date-first_date} days. He did something useful on #{date_count} of those days."
    end
  end

  def write_html_report
    template_file = File.read(File.join(File.dirname(__FILE__), "..", "assets", "gitalytics.html.erb"))
    erb = ERB.new(template_file)
    File.open("gitalytics_result.html", 'w+') { |file| file.write(erb.result(binding)) }
  end

  private
  def get_user_data(lines)
    users = lines.map{|r| [r[:name], r[:email]]}.uniq
    users.map{ |u| {
      name: u[0],
      email: u[1],
      gravatar: Digest::MD5.hexdigest(u[1]),
      color: "%06x" % (rand * 0xffffff),
      commits: lines.select{ |r| r[:name] == u[0] }
    } }
  end


end
