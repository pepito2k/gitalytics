# frozen_string_literal: true

require 'digest/md5'

class User
  attr_accessor :name, :email, :commits

  def initialize(name, email)
    self.name    = name
    self.email   = email
    self.commits = []
  end

  def gravatar
    Digest::MD5.hexdigest(email.to_s.strip.downcase)
  end

  def initials
    parts = name.to_s.split(/[\s._-]+/).reject(&:empty?)
    letters = parts.size > 1 ? [parts.first[0], parts.last[0]] : [name.to_s[0, 2]]
    letters.join.upcase
  end

  def first_commit
    commits.min_by(&:time)
  end

  def last_commit
    commits.max_by(&:time)
  end

  def commits_period
    (last_commit.date - first_commit.date).to_i + 1
  end

  def working_days
    commits.map(&:date).uniq.count
  end

  def total_insertions
    commits.sum(&:insertions)
  end

  def total_deletions
    commits.sum(&:deletions)
  end

  def total_changes
    total_insertions + total_deletions
  end

  def summary
    "#{name} has made #{commits.count} commits on #{working_days} " \
      "separate days during a span of #{commits_period} days."
  end

  def weekday_commits
    days = Array.new(7) { 0 }
    commits.each { |c| days[c.date.wday] += 1 }
    days
  end
end
