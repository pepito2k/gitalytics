# frozen_string_literal: true

require 'json'

module Gitalytics
  # Machine-readable summary of the same data the HTML report shows.
  class JsonReport
    def initialize(report)
      @report = report
    end

    def to_h
      r = @report
      return { repository: r.repo_name, commits: 0, authors: [] } if r.empty?

      {
        repository: r.repo_name,
        generated_at: r.generated_at.iso8601,
        first_commit: r.first_commit.time.iso8601,
        last_commit: r.last_commit.time.iso8601,
        commits: r.commits.size,
        insertions: r.total_insertions,
        deletions: r.total_deletions,
        files_touched: r.files_touched,
        active_days: r.active_days,
        longest_streak: r.longest_streak,
        authors: r.users.map { |u| author(u) },
        weekdays: %w[mon tue wed thu fri sat sun].zip(r.weekday_totals).to_h,
        top_files: r.top_files.map { |name, stats| { path: name, **stats } },
        top_directories: r.top_directories.map { |dir, lines| { path: dir, lines: lines } }
      }
    end

    def render
      JSON.pretty_generate(to_h)
    end

    private

    def author(user)
      {
        name: user.name,
        email: user.email,
        commits: user.commits.size,
        share: @report.share(user).round(2),
        insertions: user.total_insertions,
        deletions: user.total_deletions,
        active_days: user.working_days,
        first_commit: user.first_commit.time.iso8601,
        last_commit: user.last_commit.time.iso8601
      }
    end
  end
end
