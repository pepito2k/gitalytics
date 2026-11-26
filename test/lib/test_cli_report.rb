# frozen_string_literal: true

require File.join(File.dirname(__FILE__), '..', 'test_helper.rb')
require 'gitalytics'
require 'stringio'

class TestCliReport < Minitest::Test
  def commit(user, time, files = { 'lib/a.rb' => [3, 1] })
    Commit.new(time).tap do |c|
      c.time = Time.parse(time)
      c.date = c.time.to_date
      c.subject = 'Change'
      c.author = user
      files.each { |f, (i, d)| c.summary << { filename: f, insertions: i, deletions: d } }
      user.commits << c
    end
  end

  def setup
    @ann = User.new('Ann Lee', 'ann@example.com')
    @bob = User.new('Bob Stone', 'bob@example.com')
    @commits = [
      commit(@ann, '2024-01-01 09:15:00 +0000'),
      commit(@ann, '2024-01-02 10:00:00 +0000', 'README.md' => [1200, 0]),
      commit(@ann, '2024-01-02 23:30:00 +0000'),
      commit(@bob, '2024-01-10 14:00:00 +0000')
    ]
    @report = Gitalytics::Report.new(users: [@bob, @ann], commits: @commits, repo_name: 'demo')
  end

  def render(**opts)
    Gitalytics::CliReport.new(@report, **opts).render
  end

  def test_header_and_period
    lines = render.lines

    assert_equal "demo  4 commits by 2 authors\n", lines[0]
    assert_equal "Jan 1, 2024 to Jan 10, 2024 (10 days)\n", lines[1]
  end

  def test_overview_totals
    out = render

    assert_includes out, '+1,209 -3'
    assert_includes out, '3 of 10'
    assert_includes out, 'Jan 2, 2024 (2 commits)'
  end

  def test_author_table_is_sorted_with_share
    rows = render.lines.drop_while { |l| !l.start_with?('  Author') }

    assert_match(/Ann Lee\s+3\s+75\.0%/, rows[1])
    assert_match(/Bob Stone\s+1\s+25\.0%/, rows[2])
    assert_includes rows[1], '2024-01-02'
  end

  def test_top_limits_authors
    out = render(top: 1)

    refute_includes out, 'Bob Stone'
    assert_includes out, 'and 1 more author '
  end

  def test_no_color_by_default
    refute_includes render, "\e["
    assert_includes render(color: true), "\e[32m+1,209\e[0m"
  end

  def test_lines_fit_the_width
    [60, 80, 120].each do |width|
      render(width: width).each_line do |line|
        assert_operator line.chomp.length, :<=, width, "#{width}: #{line.inspect}"
      end
    end
  end

  def test_long_names_are_truncated
    @ann.name = 'A' * 60
    row = render(width: 80).lines.find { |l| l.include?('AAA') }

    assert_includes row, "#{'A' * 27}…"
  end

  def test_empty_repository
    report = Gitalytics::Report.new(users: [], commits: [], repo_name: 'empty')

    assert_equal "No commits found.\n", Gitalytics::CliReport.new(report).render
  end

  def test_color_detection
    tty = StringIO.new
    def tty.tty? = true

    assert Gitalytics::CliReport.color?(tty, {})
    refute Gitalytics::CliReport.color?(tty, { 'NO_COLOR' => '1' })
    refute Gitalytics::CliReport.color?(tty, { 'TERM' => 'dumb' })
    refute Gitalytics::CliReport.color?(StringIO.new, {})
  end
end
