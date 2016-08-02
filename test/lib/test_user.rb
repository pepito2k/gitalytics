require File.join(File.dirname(__FILE__), '..', 'test_helper.rb')
require 'minitest/autorun'
require 'gitalytics/user'
require 'gitalytics/commit'
require 'date'

class TestUser < MiniTest::Unit::TestCase
  def setup
    @user = User.new('John ñ Doe', 'john@doe.com')
  end

  def create_commit(hash, date, summary_data)
    Commit.new(hash).tap do |commit|
      commit.date = Date.parse(date)
      summary_data.each { |summary| commit.summary << summary }
    end
  end

  def create_commits(user)
    user.commits << create_commit(
      'abcdef',
      '2000-01-10',
      [{ filename: 'a.rb', insertions: 1, deletions: 0 }])
    user.commits << create_commit(
      'abcdef',
      '2000-01-01',
      [{ filename: 'c.rb', insertions: 0, deletions: 1 }])
    user.commits << create_commit(
      'abcdef',
      '2000-01-01',
      [{ filename: 'd.rb', insertions: 4, deletions: 5 }])
    user.commits << create_commit(
      'abcdef',
      '2000-01-08',
      [{ filename: 'e.rb', insertions: 1, deletions: 1 }])
  end

  def test_initial_color
    assert_match(/\d{1,3}, \d{1,3}, \d{1,3}/, @user.colors)
  end

  def test_gravatar_is_md5
    assert_match(/[a-f0-9]{32}/, @user.gravatar)
  end

  def test_first_commit
    create_commits(@user)

    assert_equal(Date.parse('2000-1-1'), @user.first_commit.date)
  end

  def test_last_commit
    create_commits(@user)

    assert_equal(Date.parse('2000-1-10'), @user.last_commit.date)
  end

  def test_commits_period
    create_commits(@user)

    assert_equal(10, @user.commits_period)
  end

  def test_working_days
    create_commits(@user)

    assert_equal(3, @user.working_days)
  end

  def test_weekday_commits
    create_commits(@user)

    assert_equal([0, 1, 0, 0, 0, 0, 3], @user.weekday_commits)
  end

  def test_total_insertions
    create_commits(@user)

    assert_equal(6, @user.total_insertions)
  end

  def test_total_deletions
    create_commits(@user)

    assert_equal(7, @user.total_deletions)
  end

  def test_total_changes
    create_commits(@user)

    assert_equal(13, @user.total_changes)
  end

  def test_rgba
    assert_match(/rgba\(([\d]{,3}, ){3}1\)/, @user.rgba)
  end
end
