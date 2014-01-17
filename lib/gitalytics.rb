# encoding: UTF-8

require 'date'
require 'erb'
require 'digest/md5'

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

module GitLog

  module_function

  def parse_git_log
    users = []

    log = get_log
    blocks = get_blocks(log)

    blocks.each do |(hash, block_string)|
      parse_block(hash, block_string, users)
    end

    users
  end

  def get_log
    `git log --stat --format=`
  end

  def get_blocks(log_string)
    commits = log_string.scan(/^commit [a-f0-9]+$/)
    blocks = log_string.split(/^commit [a-f0-9]+$/)
    blocks.shift # get rid of first empty string

    commits.zip(blocks)
  end

  def parse_block(hash, block_string, users)
    commit = Commit.new(hash)

    block_string.encode!('UTF-8', 'UTF8-MAC') if defined?(Encoding::UTF8_MAC)

    get_commit_author(block_string, commit, users)
    get_commit_date(block_string, commit)
    get_commit_message(block_string, commit)
    get_commit_summary(block_string, commit)

    commit
  end

  def get_commit_summary(block_string, commit)
    block_string.scan(/^ ([^ ]+)[ ]+\|[ ]+([\d]+) ([\+]*)([-]*)$/).each do |summary|
      commit.summary << {
        filename: summary[0],
        changes: summary[1],
        insertions: summary[2],
        deletions: summary[3]
      }
    end
  end

  def get_commit_date(block_string, commit)
    date = block_string.match(/^Date:   (.*)$/)[0]
    commit.date = Date.parse(date)
  end

  def get_commit_message(block_string, commit)
    message = block_string.match(/^\n(?:\s{4}.*\n)+$/).to_s
    message.gsub!(/\s{4,}/, '')
    commit.subject = message.lines.first
  end

  def get_commit_author(block_string, commit, users)
    author = block_string.match(/^Author: ([[:alpha:] ]*) <(.*)>$/)
    user = get_user(author[0], author[1], users)

    commit.author = user
    user.commits << commit
  end

  def get_user(name, email, users)
    users.each do |user|
      return user if user.email == email
    end
    users << new_user = User.new(name, email)
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
