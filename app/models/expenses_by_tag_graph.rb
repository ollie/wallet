class ExpensesByTagGraph
  attr_accessor :date

  def initialize(date)
    self.date = date
  end

  def data
    tags = {}

    Entry.expenses.by_month(date).eager(:tags).each do |entry|
      entry.primary_tags.each do |tag|
        entries = tags[tag.name] ||= []
        entries << entry.amount
      end
    end

    sorted_tags = []

    tags
      .map { |name, entries| [name, entries.sum * -1] }
      .sort { |(_, a_sum), (_, b_sum)| b_sum <=> a_sum }
      .each { |name, sum| sorted_tags << { name: name, sum: sum } }

    sorted_tags
  end
end
