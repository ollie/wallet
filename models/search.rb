class Search
  attr_accessor :query

  def initialize(query = nil)
    self.query = query.to_s.strip
  end

  def results
    @results ||= begin
      phrases = query.split('|').map(&:strip).reject(&:empty?)

      if phrases.any?
        ds = Entry.order(Sequel.desc(Sequel.lit('COALESCE(accounted_on, current_date)')), Sequel.desc(:date), Sequel.desc(:id))
        ds = ds.where(Sequel.ilike(:note, *phrases.map { |phrase| "%#{phrase}%" }))
        ds
      else
        []
      end
    end
  end
end
