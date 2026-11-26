# frozen_string_literal: true

require File.join(File.dirname(__FILE__), '..', 'test_helper.rb')
require 'gitalytics'

class TestJsonReport < Minitest::Test
  def setup
    @user = User.new('Ann Lee', 'ann@example.com')
    commit = Commit.new('abc')
    commit.time = Time.parse('2024-01-01 09:15:00 +0000')
    commit.date = commit.time.to_date
    commit.subject = 'Initial commit'
    commit.author = @user
    commit.summary << { filename: 'lib/a.rb', insertions: 3, deletions: 1 }
    @user.commits << commit
    @report = Gitalytics::Report.new(users: [@user], commits: [commit], repo_name: 'demo')
  end

  def test_summary_fields
    data = Gitalytics::JsonReport.new(@report).to_h

    assert_equal 'demo', data[:repository]
    assert_equal 1, data[:commits]
    assert_equal 3, data[:insertions]
    assert_equal 1, data[:weekdays]['mon']
    assert_equal({ path: 'lib/a.rb', commits: 1, insertions: 3, deletions: 1 }, data[:top_files].first)
  end

  def test_author_fields
    author = Gitalytics::JsonReport.new(@report).to_h[:authors].first

    assert_equal 'Ann Lee', author[:name]
    assert_in_delta 100.0, author[:share]
    assert_equal '2024-01-01T09:15:00+00:00', author[:first_commit]
  end

  def test_render_is_valid_json
    parsed = JSON.parse(Gitalytics::JsonReport.new(@report).render)

    assert_equal 'demo', parsed['repository']
  end

  def test_empty_repository
    report = Gitalytics::Report.new(users: [], commits: [], repo_name: 'empty')

    assert_equal({ repository: 'empty', commits: 0, authors: [] }, Gitalytics::JsonReport.new(report).to_h)
  end
end
