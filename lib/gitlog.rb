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
    `git log --numstat --pretty='%H %ai %an <%ae> %s'`
  end

  def get_blocks(log_string)
    commits = log_string.scan(/^([a-f0-9]{40})/).map(&:first)
    blocks = log_string.split(/^[a-f0-9]{40}/).map(&:strip)
    blocks.shift # get rid of first empty string

    commits.zip(blocks)
  end

  def parse_block(hash, block_string, users)
    commit = Commit.new(hash)

    block_string.encode!('UTF-8', 'UTF8-MAC') if defined?(Encoding::UTF8_MAC)

    regex = /^(?<date>.{25}) (?<name>.*?) \<(?<email>.*?)> (?<subject>.*?)$/
    data = block_string.match(regex)
    commit.subject = data[:subject]
    commit.date = Date.parse(data[:date])

    get_commit_author(data, commit, users)
    get_commit_summary(block_string, commit)

    commit
  end

  def get_commit_summary(block_string, commit)
    block_string.scan(/^(?<insertions>\d+)\s+(?<deletions>\d+)\s+(?<filename>.*)$/).each do |summary|
      commit.summary << {
        insertions: summary[0].to_i,
        deletions: summary[1].to_i,
        filename: summary[2],
      }
    end
  end

  def get_commit_author(data, commit, users)
    user = get_user(data[:name], data[:email], users)

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
