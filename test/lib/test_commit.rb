require 'minitest/autorun'
require 'commit'

class TestCommit < MiniTest::Unit::TestCase

  def setup
    @commit = Commit.new('abcdef0123456789')
  end

  def build_commit(commit)
    commit.summary << {
      changes: 5,
      insertions: '+++',
      deletions: '--',
      filename: 'a.rb'
    }
    commit.summary << {
      changes: 7,
      insertions: '++++',
      deletions: '---',
      filename: 'b.rb'
    }
  end

  def test_that_count_insertions
    build_commit(@commit)

    assert_equal(7, @commit.insertions)
  end

  def test_that_count_deletions
    build_commit(@commit)

    assert_equal(5, @commit.deletions)
  end

  def test_that_count_files_committed
    build_commit(@commit)

    assert_equal(['a.rb', 'b.rb'], @commit.files_committed)
  end

end
