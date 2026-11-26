# frozen_string_literal: true

require File.join(File.dirname(__FILE__), '..', 'test_helper.rb')
require 'minitest/autorun'
require 'gitalytics/gitlog'

class TestGitLog < Minitest::Test
  RS = GitLog::RECORD_SEP
  FS = GitLog::FIELD_SEP

  def header(sha, date, name, email, subject)
    "#{RS}#{[sha * 40, date, name, email, subject].join(FS)}"
  end

  def parse(*records, group_by: 'name')
    GitLog.parse(records.join.each_line(RS), group_by)
  end

  def test_parses_header_and_numstat
    data = parse(header('a', '2024-03-01T10:20:30-03:00', 'Ann <Dev>', 'ann@x.io', 'Fix => thing'),
                 "\n3\t1\tlib/a b.rb\0\0")
    commit = data[:commits].first

    assert_equal 'a' * 40, commit.sha
    assert_equal 'Ann <Dev>', commit.author.name
    assert_equal 'Fix => thing', commit.subject
    assert_equal Time.iso8601('2024-03-01T10:20:30-03:00'), commit.time
    assert_equal Date.new(2024, 3, 1), commit.date
    assert_equal [{ insertions: 3, deletions: 1, filename: 'lib/a b.rb', binary: false }], commit.summary
  end

  def test_binary_files_are_counted_without_lines
    commit = parse(header('a', '2024-03-01T10:00:00+00:00', 'Ann', 'ann@x.io', 'logo'),
                   "\n-\t-\tlogo.png\0\0")[:commits].first

    assert_equal ['logo.png'], commit.files_committed
    assert commit.summary.first[:binary]
    assert_equal 0, commit.insertions
  end

  def test_merge_commits_without_stats
    data = parse(header('b', '2024-03-02T10:00:00+00:00', 'Ann', 'ann@x.io', 'Merge branch x'), "\0",
                 header('a', '2024-03-01T10:00:00+00:00', 'Ann', 'ann@x.io', 'one'), "\n1\t0\ta.rb\0\0")

    assert_equal 2, data[:commits].size
    assert_empty data[:commits].first.summary
  end

  def test_renames_are_attributed_to_the_current_path
    data = parse(
      header('c', '2024-03-03T10:00:00+00:00', 'Ann', 'ann@x.io', 'edit'), "\n2\t0\tlib/new.rb\0\0",
      header('b', '2024-03-02T10:00:00+00:00', 'Ann', 'ann@x.io', 'move'), "\n1\t1\t\0lib/old.rb\0lib/new.rb\0\0",
      header('a', '2024-03-01T10:00:00+00:00', 'Ann', 'ann@x.io', 'add'), "\n5\t0\tlib/old.rb\0\0"
    )

    assert_equal [['lib/new.rb']] * 3, data[:commits].map(&:files_committed)
  end

  def test_rename_chains_resolve_to_the_latest_name
    data = parse(
      header('c', '2024-03-03T10:00:00+00:00', 'Ann', 'ann@x.io', 'b to c'), "\n0\t0\t\0b.rb\0c.rb\0\0",
      header('b', '2024-03-02T10:00:00+00:00', 'Ann', 'ann@x.io', 'a to b'), "\n0\t0\t\0a.rb\0b.rb\0\0",
      header('a', '2024-03-01T10:00:00+00:00', 'Ann', 'ann@x.io', 'add'), "\n5\t0\ta.rb\0\0"
    )

    assert_equal [['c.rb']] * 3, data[:commits].map(&:files_committed)
  end

  def test_invalid_bytes_do_not_crash
    name = (+"Jos\xE9").force_encoding(Encoding::BINARY)
    commit = parse(header('a', '2024-03-01T10:00:00+00:00', name, 'jose@x.io', 'hola'),
                   "\n1\t0\ta.rb\0\0")[:commits].first

    assert_predicate commit.author.name, :valid_encoding?
    assert_equal 'Jos?', commit.author.name
  end

  def test_names_are_unicode_normalized
    decomposed = 'José'
    data = parse(header('b', '2024-03-02T10:00:00+00:00', decomposed, 'j@x.io', 'two'), "\0",
                 header('a', '2024-03-01T10:00:00+00:00', 'José', 'j@x.io', 'one'), "\0")

    assert_equal ['José'], data[:users].map(&:name)
  end

  def test_group_by_name
    data = parse(header('b', '2024-03-02T10:00:00+00:00', 'Ann', 'ann@work.io', 'two'), "\0",
                 header('a', '2024-03-01T10:00:00+00:00', 'Ann', 'ann@home.io', 'one'), "\0")

    assert_equal 1, data[:users].size
    assert_equal 2, data[:users].first.commits.size
  end

  def test_group_by_email_ignores_case
    data = parse(header('c', '2024-03-03T10:00:00+00:00', 'Ann', 'Ann@X.io', 'three'), "\0",
                 header('b', '2024-03-02T10:00:00+00:00', 'Ann B.', 'ann@x.io', 'two'), "\0",
                 header('a', '2024-03-01T10:00:00+00:00', 'Bob', 'bob@x.io', 'one'), "\0",
                 group_by: 'email')

    assert_equal([2, 1], data[:users].map { |u| u.commits.size })
  end

  def test_parse_does_not_keep_state_between_calls
    record = [header('a', '2024-03-01T10:00:00+00:00', 'Ann', 'ann@x.io', 'one'), "\0"]
    parse(*record)

    assert_equal 1, parse(*record)[:commits].size
  end

  def test_git_log_command_without_filters
    assert_equal ['git', '-c', 'core.quotePath=false', 'log', '--numstat', '-z', GitLog::PRETTY],
                 GitLog.git_log_command
  end

  def test_git_log_command_with_filters
    cmd = GitLog.git_log_command(since: '2024-01-01', until_date: '6 months ago', no_merges: true)

    assert_includes cmd, '--since=2024-01-01'
    assert_includes cmd, '--until=6 months ago'
    assert_includes cmd, '--no-merges'
  end
end
