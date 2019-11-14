class Search
  attr_accessor :query, :page

  def initialize(query: nil, page: nil)
    self.query = query.to_s.strip
    self.page  = (page || 1).to_i || 1
  end

  def results
    @results ||= begin
      phrases = query.split('|').map(&:strip).reject(&:empty?)

      if phrases.any?
        GroupsList.search(phrases, page)
      else
        GroupsList.new
      end
    end
  end
end
