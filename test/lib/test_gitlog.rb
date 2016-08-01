require File.join(File.dirname(__FILE__), '..', 'test_helper.rb')
require 'minitest/autorun'
require 'gitalytics/gitlog'

class TestCommit < MiniTest::Unit::TestCase

  def git_log

    %q(bea63e76c7c6d5afd42ac5b24a911b36e5c261f9 2013-02-13 23:11:16 -0200 Gonzalo Robaina <gonzalor@gmail.com> Print basic commit report on the console

6       1       bin/gitalytics
33      6       lib/gitalytics.rb
d392710a9e657c72e73ca87df3ed2c8c802441e4 2012-12-19 06:04:59 -0800 Gonzalo Robaina <gonzalor@gmail.com> Initial commit

16      0       .gitignore
4       0       README.md
9a99ae5dbc1eaadf268ca925cce9b68d10216151 2012-12-06 10:29:49 -0200 Gonzalo Robaina <gonzalor@gmail.com> initial commit

1       0       README.md
3       0       bin/gitalytics
13      0       gitalytics.gemspec
49      0       lib/gist.rb
11      0       lib/gitalytics.rb
)
  end

  def test_get_blocks
    expected_blocks = [
      %q(2013-02-13 23:11:16 -0200 Gonzalo Robaina <gonzalor@gmail.com> Print basic commit report on the console

6       1       bin/gitalytics
33      6       lib/gitalytics.rb),

      %q(2012-12-19 06:04:59 -0800 Gonzalo Robaina <gonzalor@gmail.com> Initial commit

16      0       .gitignore
4       0       README.md),

      %q(2012-12-06 10:29:49 -0200 Gonzalo Robaina <gonzalor@gmail.com> initial commit

1       0       README.md
3       0       bin/gitalytics
13      0       gitalytics.gemspec
49      0       lib/gist.rb
11      0       lib/gitalytics.rb)
    ]

    expected_commits = [
      'bea63e76c7c6d5afd42ac5b24a911b36e5c261f9',
      'd392710a9e657c72e73ca87df3ed2c8c802441e4',
      '9a99ae5dbc1eaadf268ca925cce9b68d10216151',
    ]
    blocks = GitLog.get_blocks(git_log)

    assert_equal(expected_commits, blocks.map(&:first))
    assert_equal(expected_blocks, blocks.map(&:last))
  end

  def test_parse_block
    blocks = GitLog.get_blocks(git_log)
    hash, block = blocks.last

    users = []
    commit = GitLog.parse_block(hash, block, users, 'email')

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
    users = []
    user = GitLog.get_user('name', 'email@example.com', users, 'name')

    assert_equal(1, users.count)
    assert_equal(user, users.last)
    assert_equal('name', user.name)
    assert_equal('email@example.com', user.email)
  end

  def test_get_user_returns_the_user
    users = [User.new('name', 'email@example.com')]

    user = GitLog.get_user('name', 'email@example.com', users, 'email')
    assert_equal(user, users.last)
    assert_equal('name', user.name)
    assert_equal('email@example.com', user.email)
  end

  def test_get_commit_author_links_user_and_commit
    data = { name: 'test', email: 'test@email.com' }
    commit = Commit.new(hash)
    users = []

    GitLog.get_commit_author(data, commit, users, 'name')
    assert_equal(users.last, commit.author)
    assert_equal(users.last.commits.last, commit)
  end
end
