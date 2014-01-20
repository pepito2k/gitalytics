require 'commit'
require 'user'
require 'date'

module GitLog

  module_function

  def parse_git_log
    users, commits = [], []

    log = get_log
    blocks = get_blocks(log)

    blocks.each do |(hash, block_string)|
      commits << parse_block(hash, block_string, users)
    end

    {users: users, commits: commits}
  end

  def get_log
    `git log --stat --format=`
  end

  def get_blocks(log_string)
    commits = log_string.scan(/^commit ([a-f0-9]+)$/).map(&:first)
    blocks = log_string.split(/^commit [a-f0-9]+$/).map(&:strip)
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
    commit.subject = message.lines.first.strip
  end

  def get_commit_author(block_string, commit, users)
    author = block_string.match(/^Author: ([[:alpha:] ]*) <(.*)>$/)
    user = get_user(author[1], author[2], users)

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
