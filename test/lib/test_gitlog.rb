require File.join(File.dirname(__FILE__), '..', 'test_helper.rb')
require 'minitest/autorun'
require 'gitalytics/gitlog'

class TestCommit < MiniTest::Unit::TestCase
  GIT_LOG = File.read(File.join('test', 'files', 'git_log'))

  def setup
    GitLog.instance_variable_set(:@users, [])
  end

  def test_get_blocks
    expected_blocks = [
      File.read(File.join('test', 'files', 'block1')),
      File.read(File.join('test', 'files', 'block2')),
      File.read(File.join('test', 'files', 'block3'))
    ]

    expected_commits = [
      'bea63e76c7c6d5afd42ac5b24a911b36e5c261f9',
      'd392710a9e657c72e73ca87df3ed2c8c802441e4',
      '9a99ae5dbc1eaadf268ca925cce9b68d10216151'
    ]

    blocks = GitLog.get_blocks(GIT_LOG)
    # require 'byebug'; byebug

    assert_equal(expected_commits, blocks.map(&:first))
    assert_equal(expected_blocks, blocks.map(&:last))
  end

  def test_parse_block
    blocks = GitLog.get_blocks(GIT_LOG)
    hash, block = blocks.last

    commit = GitLog.parse_block(hash, block, 'email')

    assert_equal(
      ['README.md', 'bin/gitalytics', 'gitalytics.gemspec', 'lib/gist.rb', 'lib/gitalytics.rb'],
      commit.files_committed
    )
    assert_equal(77, commit.insertions)
    assert_equal(0, commit.deletions)
    assert_equal('Gonzalo Robaina', commit.author.name)
    assert_equal('gonzalor@gmail.com', commit.author.email)
    assert_equal('initial commit', commit.subject)
  end

  def test_get_user_creates_the_user
    blocks = GitLog.get_blocks(GIT_LOG)
    hash, block = blocks.last
    GitLog.parse_block(hash, block, 'email')

    user = GitLog.get_user('name', 'email@example.com', 'name')
    users = GitLog.instance_variable_get("@users")

    assert_equal(2, users.count)
    assert_equal(user, users.last)
    assert_equal('name', user.name)
    assert_equal('email@example.com', user.email)
  end

  def test_get_user_returns_the_user
    users = [User.new('name', 'email@example.com')]

    user = GitLog.get_user('name', 'email@example.com', 'email')
    # assert_equal(user, users.last)
    assert_equal('name', user.name)
    assert_equal('email@example.com', user.email)
  end

  def test_get_commit_author_links_user_and_commit
    data = { name: 'name', email: 'email@example.com' }
    commit = Commit.new(hash)

    GitLog.get_commit_author(data, commit, 'name')
    # assert_equal(users.last, commit.author)
    # assert_equal(users.last.commits.last, commit)
  end
end
