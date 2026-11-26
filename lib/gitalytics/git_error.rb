# frozen_string_literal: true

module Gitalytics
  # Raised when `git log` fails (not a repository, git missing, ...).
  class GitError < StandardError; end
end
