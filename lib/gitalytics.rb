require 'date'

class Gitalytics
  def log_to_hash
    docs = []
    cmd  = "git log --pretty='%cn|%cd|%s'"
    res  = `#{cmd}`

    res.each_line do |line|
      parts = line.split('|')
      docs << {:username => parts[0], :date => Date.parse(parts[1]), :subject => parts[2]}
    end

    return  {
      :users => docs.map{|r| r[:username]}.uniq,
      :dates => docs.map{|r| r[:date]}.uniq,
      :records => docs
    }
  end

  def output_summary_report(res)
    # Report how many commits over time
    res[:users].each do |user|
      dates_for_user = res[:records].select{|r| r[:username] == user}.map{|r| r[:date]}
      commit_count   = dates_for_user.count
      date_count     = dates_for_user.uniq.count
      first_date     = dates_for_user.min
      last_date      = dates_for_user.max
      puts "#{user} has made #{commit_count} commits over the last #{last_date-first_date} days. He did something useful on #{date_count} of those days."
    end
  end
end

# class Commit
#   attr_accesor :author, :message, :date
# end

# class Author
#   attr_accesor :name, :email
# end
