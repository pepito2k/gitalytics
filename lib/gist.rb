# Simple Git Analyzer
#
# WORK IN PROGRESS :)
#
# Tobin Harris (tobin@tobinharris.com)
# http://tobinharris.com
# http://engineroomapps.com
# Class to analyze git log
require 'rubygems'

class Gitalyzer

  # scrape the Git log for current directory and
  # make into a hash we can fart about with using Ruby
  def log_to_hash
    docs = []
    #cmd = "git log --pretty='%cn|%ce|%ct|%s'"
    cmd = "git log --pretty='%cn|%cd|%s'"
    res = `#{cmd}`
    res.each_line do |line|
      parts = line.split('|')
      docs << {:username=>parts[0], :date=>Date.parse(parts[1]), :subject=>parts[2]}
    end

    return  {
      :users=> docs.map{|r| r[:username]}.uniq,
      :dates=> docs.map{|r| r[:date]}.uniq,
      :records => docs
    }
  end
end

# Sample Report that works with the record
def output_summary_report(res)
  # Report how many commits over time
  res[:users].each do |user|
    dates_for_user = res[:records].select{|r| r[:username]==user}.map{|r| r[:date]}
    commit_count = dates_for_user.count
    date_count = dates_for_user.uniq.count
    first_date = dates_for_user.min
    last_date = dates_for_user.max
    puts "#{user} has made #{commit_count} commits over the last #{last_date-first_date} days. He did something useful on #{date_count} of those days."
  end
end

Dir.chdir($1 || '.')
g = Gitalyzer.new
res = g.log_to_hash
output_summary_report(res)