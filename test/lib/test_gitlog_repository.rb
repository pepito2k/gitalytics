# frozen_string_literal: true

require File.join(File.dirname(__FILE__), '..', 'test_helper.rb')
require 'minitest/autorun'
require 'tmpdir'
require 'gitalytics/gitlog'

# Runs GitLog against throwaway repositories built with the real git binary.
class TestGitLogRepository < Minitest::Test
  def git(*args, env: {})
    system(env, 'git', *args, out: File::NULL, err: File::NULL) || flunk("git #{args.join(' ')} failed")
  end

  def in_repo
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        git 'init', '-q'
        git 'config', 'user.name', 'Ann'
        git 'config', 'user.email', 'ann@x.io'
        git 'config', 'commit.gpgsign', 'false'
        yield
      end
    end
  end

  def commit_file(path, content, message, env: {})
    File.write(path, content)
    git 'add', path
    git 'commit', '-q', '-m', message, env: env
  end

  def test_reads_a_real_repository
    in_repo do
      commit_file("caf\u00e9 notes.txt", "a\nb\n", 'first')
      commit_file('logo.bin', "\x00\x01".b, 'binary')
      git 'mv', "caf\u00e9 notes.txt", 'notes.txt'
      git 'commit', '-q', '-m', 'rename'
      bob = { 'GIT_AUTHOR_NAME' => 'bob', 'GIT_AUTHOR_EMAIL' => 'BOB@x.io' }
      commit_file('b.txt', "x\n", 'by bob', env: bob)
      commit_file('.mailmap', "Bob Builder <bob@x.io> <BOB@x.io>\n", 'mailmap')

      data = GitLog.parse_git_log('name')

      assert_equal ['mailmap', 'by bob', 'rename', 'binary', 'first'], data[:commits].map(&:subject)
      assert_equal ['Ann', 'Bob Builder'], data[:users].map(&:name).sort
      assert_equal ['notes.txt'], data[:commits].last.files_committed
      assert data[:commits][3].summary.first[:binary]
    end
  end

  def test_no_merges
    in_repo do
      commit_file('a.txt', "a\n", 'first')
      git 'checkout', '-q', '-b', 'topic'
      commit_file('b.txt', "b\n", 'topic work')
      git 'checkout', '-q', '-'
      commit_file('c.txt', "c\n", 'main work')
      git 'merge', '-q', '--no-ff', '-m', 'Merge topic', 'topic'

      assert_equal 4, GitLog.parse_git_log('name')[:commits].size
      assert_equal 3, GitLog.parse_git_log('name', no_merges: true)[:commits].size
    end
  end

  def test_empty_repository
    in_repo do
      assert_empty GitLog.parse_git_log('name')[:commits]
    end
  end

  def test_outside_a_repository_raises
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        error = assert_raises(Gitalytics::GitError) do
          GitLog.parse_git_log('name')
        end
        assert_match(/not a git repository/, error.message)
      end
    end
  end
end
