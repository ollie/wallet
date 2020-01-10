class Search
  attr_accessor :query, :date_from, :date_to, :page

  def initialize(query: nil, date_from: nil, date_to: nil, page: nil)
    self.query     = query.to_s.strip
    self.date_from = date_from.to_s.strip
    self.date_to   = date_to.to_s.strip
    self.page      = (page || 1).to_i || 1
  end

  def results
    @results ||= begin
      phrases = query.split('|').map(&:strip).reject(&:empty?)

      if phrases.any?
        date_from = Date.parse(self.date_from) if self.date_from.present?
        date_to   = Date.parse(self.date_to)   if self.date_to.present?

        GroupsList.search(phrases, date_from, date_to, page)
      else
        GroupsList.new
      end
    end
  end
end
