# frozen_string_literal: true

class Commit
  attr_accessor :sha, :author, :author_name, :author_email, :date, :time, :subject, :summary

  def initialize(sha)
    self.sha = sha
    self.summary = []
  end

  def insertions
    summary.sum { |s| s[:insertions] }
  end

  def deletions
    summary.sum { |s| s[:deletions] }
  end

  def files_committed
    summary.map { |s| s[:filename] }
  end
end
