class Search
  attr_accessor :query

  def initialize(query = nil)
    self.query = query.to_s.strip
  end

  def results
    @results ||= begin
      phrases = query.split('|').map(&:strip).reject(&:empty?)

      if phrases.any?
        GroupsList.search(phrases)
      else
        GroupsList.new
      end
    end
  end
end
