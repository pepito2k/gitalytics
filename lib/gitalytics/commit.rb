class Commit
  attr_accessor :hash, :author, :date, :subject, :summary

  def initialize(hash)
    self.hash = hash
    self.summary = []
  end

  def insertions
    summary.inject(0) { |a, e| a + e[:insertions] }
  end

  def deletions
    summary.inject(0) { |a, e| a + e[:deletions] }
  end

  def files_committed
    summary.map { |s| s[:filename] }
  end
end
