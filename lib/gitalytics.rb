# encoding: UTF-8

require 'date'
require 'erb'
require 'digest/md5'

class Gitalytics

  VERSION = '1.1.1'

  attr_accessor :data

  def initialize
    @data = { commits: [], users: [] }
  end

  def analyze(options)
    parse_git_log
    case options[:format]
    when 'html'
      output_html_report
    else
      output_cli_report
    end
  end

  private
  def parse_git_log
    result = `git log --stat --format=`

    result.each_line do |line|
      line.encode!('UTF-8', 'UTF8-MAC') if defined?(Encoding::UTF8_MAC)

      if match = line.match(/^commit ([0-9a-z]*)$/)
        @data[:commits] << Commit.new(match[1])
      elsif match = line.match(/^Author: ([[:alpha:] ]*) <(.*)>$/)
        user = get_user(match[1], match[2])
        @data[:commits].last.author = user
        user.commits << @data[:commits].last
      elsif match = line.match(/^Date:   (.*)$/)
        @data[:commits].last.date = Date.parse(match[1])
      elsif match = line.match(/^    (.*)$/)
        @data[:commits].last.subject = match[1]
      elsif match = line.match(/^ ([^ ]+)[ ]+\|[ ]+([\d]+) ([\+]*)([-]*)$/)
        @data[:commits].last.summary << { filename: match[1], changes: match[2], insertions: match[3], deletions: match[4] }
      end
    end

  end

  def output_cli_report
    @data[:users].each do |user|
      puts user.summary
    end
  end

  def output_html_report
    template_file = File.read(File.join(File.dirname(__FILE__), "..", "assets", "gitalytics.html.erb"))
    erb = ERB.new(template_file)
    File.open("gitalytics_result.html", 'w+') { |file| file.write(erb.result(binding)) }
  end

  def get_user(name, email)
    @data[:users].each do |u|
      return u if u.email == email
    end
    @data[:users] << new_user = User.new(name, email)
    new_user
  end

end

class User

  attr_accessor :name, :email, :commits, :colors

  def initialize(name, email)
    self.name = name
    self.email = email
    self.commits = []
    self.colors = [rand(255), rand(255), rand(255)].join(', ')
  end

  def gravatar
    Digest::MD5.hexdigest(email)
  end

  def first_commit
    commits.min_by(&:date)
  end

  def last_commit
    commits.max_by(&:date)
  end

  def commits_period
    (last_commit.date - first_commit.date).to_i + 1
  end

  def working_days
    commits.map(&:date).uniq.count
  end

  def total_insertions
    commits.map(&:insertions).inject(0) { |total, current| total + current }
  end

  def total_deletions
    commits.map(&:deletions).inject(0) { |total, current| total + current }
  end

  def summary
    "#{name} has made #{commits.count} commits between #{commits_period} days. He/she did something useful on #{working_days} of those days."
  end

  def rgba(opacity = 1)
    "rgba(#{colors}, #{opacity})"
  end

  def weekday_commits
    days = Array.new(7) {0}
    commits.each do |c|
      days[c.date.wday] += 1
    end
    days
  end

end

class Commit

  attr_accessor :hash, :author, :date, :subject, :summary

  def initialize(hash)
    self.hash = hash
    self.summary = []
  end

  def insertions
    summary.map{ |s| s[:insertions].length }.inject(0){ |total, current| total + current }
  end

  def deletions
    summary.map{ |s| s[:deletions].length }.inject(0){ |total, current| total + current }
  end

end
