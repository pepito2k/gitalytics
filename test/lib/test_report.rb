require File.join(File.dirname(__FILE__), '..', 'test_helper.rb')
require 'minitest/autorun'
require 'gitalytics'

class TestReport < Minitest::Test
  def commit(user, time, subject, files = { 'lib/a.rb' => [3, 1] })
    Commit.new(time.to_s).tap do |c|
      c.time = Time.parse(time)
      c.date = c.time.to_date
      c.subject = subject
      c.author = user
      files.each { |f, (i, d)| c.summary << { filename: f, insertions: i, deletions: d } }
      user.commits << c
    end
  end

  def setup
    @ann = User.new('Ann Lee', 'ann@example.com')
    @bob = User.new('Bob <script>', 'bob@example.com')
    @commits = [
      commit(@ann, '2024-01-01 09:15:00 +0000', 'Initial commit'),
      commit(@ann, '2024-01-02 10:00:00 +0000', 'Add feature', 'README.md' => [10, 0]),
      commit(@ann, '2024-01-03 23:30:00 +0000', 'Fix'),
      commit(@bob, '2024-01-10 14:00:00 +0000', 'A much longer commit message <b>here</b>')
    ]
    @report = Gitalytics::Report.new(users: [@bob, @ann], commits: @commits.reverse,
                                     repo_name: 'demo', generated_at: Time.at(0))
  end

  def test_orders_users_by_commit_count
    assert_equal [@ann, @bob], @report.users
  end

  def test_totals
    assert_equal 19, @report.total_insertions
    assert_equal 3, @report.total_deletions
    assert_equal 2, @report.files_touched
    assert_equal 4, @report.active_days
    assert_equal 10, @report.span_days
    assert_equal 3, @report.longest_streak
  end

  def test_weekly_timeline_buckets
    assert_equal :week, @report.bucket_unit
    assert_equal [3, 1], @report.timeline.map(&:last)
  end

  def test_punch_card_rows_start_on_monday
    assert_equal 1, @report.punch_card[0][9] # Monday 09h
    assert_equal 1, @report.punch_card[2][23] # Wednesday 23h
    assert_equal 4, @report.weekday_totals.sum
  end

  def test_top_files_by_churn
    assert_equal ['lib/a.rb', 'README.md'], @report.top_files.map(&:first)
    assert_equal({ commits: 3, insertions: 9, deletions: 3 }, @report.top_files.first.last)
  end

  def test_top_directories
    assert_equal [['lib/', 12], ['(root)', 10]], @report.top_directories
  end

  def test_colors_follow_rank
    assert_equal Gitalytics::Report::PALETTE[0], @report.color_for(@ann)
    assert_equal Gitalytics::Report::PALETTE[1], @report.color_for(@bob)
  end

  def test_render_is_self_contained_and_escaped
    html = @report.render
    assert_includes html, '<title>demo · Gitalytics</title>'
    assert_includes html, 'Bob &lt;script&gt;'
    refute_includes html, 'Bob <script>'
    refute_match(/<script src=|<link [^>]*stylesheet/, html)
    assert_includes html, '<svg'
  end

  def test_render_without_commits
    html = Gitalytics::Report.new(users: [], commits: [], repo_name: 'empty').render
    assert_includes html, 'no commits to analyze'
  end
end
