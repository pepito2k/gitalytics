class Commit

  attr_accessor :hash, :author, :date, :subject, :summary

  def initialize(hash)
    self.hash = hash
    self.summary = []
  end

  def insertions
    summary.inject(0) { |total, current| total + current[:insertions] }
  end

  def deletions
    summary.inject(0) { |total, current| total + current[:deletions] }
  end

  def files_committed
    summary.map{ |s| s[:filename] }
  end

end
