class Commit

  attr_accessor :hash, :author, :date, :subject, :summary

  def initialize(hash)
    self.hash = hash
    self.summary = []
  end

  def insertions
    summary.map{ |s| s[:insertions].length }.inject(0){ |total, current| total + current }
  end

  def deletions
    summary.map{ |s| s[:deletions].length }.inject(0){ |total, current| total + current }
  end

end
