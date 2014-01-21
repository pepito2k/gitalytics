require 'minitest/autorun'
require 'gitlog'

class TestCommit < MiniTest::Unit::TestCase

  def git_log
    %q(commit bea63e76c7c6d5afd42ac5b24a911b36e5c261f9
Author: Gonzalo Robaina <gonzalor@gmail.com>
Date:   Wed Feb 13 23:11:16 2013 -0200

    Print basic commit report on the console

 bin/gitalytics    |  7 ++++++-
 lib/gitalytics.rb | 39 +++++++++++++++++++++++++++++++++------
 2 files changed, 39 insertions(+), 7 deletions(-)

commit d392710a9e657c72e73ca87df3ed2c8c802441e4
Author: Gonzalo Robaina <gonzalor@gmail.com>
Date:   Wed Dec 19 06:04:59 2012 -0800

    Initial commit

 .gitignore | 16 ++++++++++++++++
 README.md  |  4 ++++
 2 files changed, 20 insertions(+)

commit 9a99ae5dbc1eaadf268ca925cce9b68d10216151
Author: Gonzalo Robaina <gonzalor@gmail.com>
Date:   Thu Dec 6 10:29:49 2012 -0200

    initial commit

 README.md          |  1 +
 bin/gitalytics     |  3 +++
 gitalytics.gemspec | 13 +++++++++++++
 lib/gist.rb        | 49 +++++++++++++++++++++++++++++++++++++++++++++++++
 lib/gitalytics.rb  | 11 +++++++++++
 5 files changed, 77 insertions(+))
  end

  def test_get_blocks
    expected_blocks = [
      %q(Author: Gonzalo Robaina <gonzalor@gmail.com>
Date:   Wed Feb 13 23:11:16 2013 -0200

    Print basic commit report on the console

 bin/gitalytics    |  7 ++++++-
 lib/gitalytics.rb | 39 +++++++++++++++++++++++++++++++++------
 2 files changed, 39 insertions(+), 7 deletions(-)),

      %q(Author: Gonzalo Robaina <gonzalor@gmail.com>
Date:   Wed Dec 19 06:04:59 2012 -0800

    Initial commit

 .gitignore | 16 ++++++++++++++++
 README.md  |  4 ++++
 2 files changed, 20 insertions(+)),

      %q(Author: Gonzalo Robaina <gonzalor@gmail.com>
Date:   Thu Dec 6 10:29:49 2012 -0200

    initial commit

 README.md          |  1 +
 bin/gitalytics     |  3 +++
 gitalytics.gemspec | 13 +++++++++++++
 lib/gist.rb        | 49 +++++++++++++++++++++++++++++++++++++++++++++++++
 lib/gitalytics.rb  | 11 +++++++++++
 5 files changed, 77 insertions(+))
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
    commit = GitLog.parse_block(hash, block, users)

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
    user = GitLog.get_user('name', 'email@example.com', users)

    assert_equal(1, users.count)
    assert_equal(user, users.last)
    assert_equal('name', user.name)
    assert_equal('email@example.com', user.email)
  end

  def test_get_user_returns_the_user
    users = [User.new('name', 'email@example.com')]

    user = GitLog.get_user('name', 'email@example.com', users)
    assert_equal(user, users.last)
    assert_equal('name', user.name)
    assert_equal('email@example.com', user.email)
  end

  def test_get_commit_author_links_user_and_commit
    blocks = GitLog.get_blocks(git_log)
    hash, block = blocks.last
    commit = Commit.new(hash)
    users = []

    GitLog.get_commit_author(block, commit, users)
    assert_equal(users.last, commit.author)
    assert_equal(users.last.commits.last, commit)
  end

  def test_get_commit_message_with_no_new_line_at_end
    block_string = "Author: User <email@example.com>\nDate:   Mon Jan 20 00:00:00 2014 -0100\n\n    Some commit\n    \n    A little description"
    commit = Commit.new('abcdef')

    GitLog.get_commit_message(block_string, commit)
    assert_equal('Some commit', commit.subject)
  end

end

