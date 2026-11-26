# frozen_string_literal: true

require 'gitalytics/commit'
require 'gitalytics/git_error'
require 'gitalytics/user'
require 'date'
require 'open3'
require 'time'

# Runs `git log` and turns its output into Commit and User objects.
#
# The log is requested with `-z` and ASCII control characters as separators,
# so author names, subjects and file names (spaces, quotes, non-ASCII, `=>`)
# never collide with the format. Records are parsed as they stream in, so big
# histories are never held in memory as a single string.
module GitLog
  module_function

  RECORD_SEP = "\x1e"
  FIELD_SEP  = "\x1f"
  # Author fields use %aN/%aE so .mailmap is respected; %aI is strict ISO 8601.
  PRETTY = "--pretty=format:#{RECORD_SEP}%H#{FIELD_SEP}%aI#{FIELD_SEP}%aN#{FIELD_SEP}%aE#{FIELD_SEP}%s".freeze
  EMPTY_REPO = /does not have any commits yet|bad default revision 'HEAD'/

  def parse_git_log(group_by = 'name', since: nil, until_date: nil, no_merges: false)
    cmd = git_log_command(since: since, until_date: until_date, no_merges: no_merges)
    Open3.popen3(*cmd) do |stdin, stdout, stderr, wait|
      stdin.close
      errors = Thread.new { stderr.read }
      data = parse(stdout.each_line(RECORD_SEP), group_by)
      status = wait.value
      check_status!(status, errors.value)
      data
    end
  rescue Errno::ENOENT
    raise Gitalytics::GitError, 'git executable not found in PATH'
  end

  def git_log_command(since: nil, until_date: nil, no_merges: false)
    cmd = ['git', '-c', 'core.quotePath=false', 'log', '--numstat', '-z', PRETTY]
    cmd << '--no-merges' if no_merges
    cmd << "--since=#{since}" if since
    cmd << "--until=#{until_date}" if until_date
    cmd
  end

  def check_status!(status, error_output)
    return if status.success?
    return if error_output.match?(EMPTY_REPO)

    message = error_output.strip.sub(/\Afatal:\s*/, '')
    raise Gitalytics::GitError, message.empty? ? "git log exited with status #{status.exitstatus}" : message
  end

  # Parses an enumerable of raw records (as produced by `git_log_command`).
  # Returns { users: [User], commits: [Commit] }, commits newest first.
  def parse(records, group_by = 'name')
    users = {}
    commits = []
    renames = {}

    records.each do |record|
      record = clean(record.chomp(RECORD_SEP))
      next if record.empty?

      commit = parse_record(record, renames)
      next unless commit

      key = user_key(commit, group_by)
      user = users[key] ||= User.new(commit.author_name, commit.author_email)
      commit.author = user
      user.commits << commit
      commits << commit
    end

    { users: users.values, commits: commits }
  end

  # A record is "<header>\n<numstat entries>" where every numstat entry ends in
  # NUL. A commit without file changes (e.g. a merge) is "<header>\0".
  def parse_record(record, renames)
    header, stats = record.split(/[\n\0]/, 2)
    sha, date, name, email, subject = header.split(FIELD_SEP, 5)
    return unless sha && date

    commit = Commit.new(sha)
    commit.author_name  = name.to_s
    commit.author_email = email.to_s
    commit.subject      = subject.to_s
    commit.time         = Time.iso8601(date)
    commit.date         = commit.time.to_date
    parse_numstat(stats.to_s, commit, renames)
    commit
  end

  # Entries look like "12\t3\tpath" or, for renames and copies,
  # "12\t3\t" followed by two more NUL-terminated fields (old and new path).
  # Binary files report "-" instead of line counts.
  #
  # git log lists newest commits first, so when a rename shows up every older
  # entry for the old path belongs to the same file: `renames` maps old paths
  # to the file's current name, keeping per-file stats together.
  def parse_numstat(stats, commit, renames)
    fields = stats.split("\0")
    until fields.empty?
      insertions, deletions, path = fields.shift.split("\t", 3)
      next unless deletions

      path = read_rename(fields, renames) if path.to_s.empty?
      next unless path

      commit.summary << {
        insertions: insertions.to_i,
        deletions: deletions.to_i,
        filename: renames.fetch(path, path),
        binary: insertions == '-'
      }
    end
  end

  # Consumes the old/new path pair of a rename entry and returns the new path.
  def read_rename(fields, renames)
    old_path = fields.shift
    new_path = fields.shift
    renames[old_path] = renames.fetch(new_path, new_path) if old_path && new_path && old_path != new_path
    new_path
  end

  def user_key(commit, group_by)
    group_by == 'email' ? commit.author_email.downcase : commit.author_name
  end

  # git emits whatever bytes are stored in the commit; older repositories
  # often contain Latin-1 names and messages. Never let that crash parsing.
  def clean(string)
    string = string.dup.force_encoding(Encoding::UTF_8)
    string = string.scrub('?') unless string.valid_encoding?
    string.ascii_only? ? string : string.unicode_normalize(:nfc)
  end
end
