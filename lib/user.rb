require 'digest/md5'

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
