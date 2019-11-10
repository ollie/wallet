module Charts
  class ExpensesByTagChart
    attr_accessor :date

    def initialize(date)
      self.date = date
    end

    def data
      from = Date.new(date.year, date.month, 1)
      to   = Date.new(date.year, date.month, -1)

      Settings
        .database[:tags]
        .select(
          Sequel[:tags][:name],
          Sequel.lit('-sum(entries.amount)').as(:sum)
        )
        .join(:taggings, tag_id: :id)
        .join(:entries, id: Sequel[:taggings][:entry_id])
        .where(Sequel.function(:coalesce, Sequel[:entries][:accounted_on], Sequel.lit('current_date')) => from..to)
        .where(Sequel[:tags][:primary] => true)
        .where(Sequel.lit('entries.amount < 0'))
        .group(Sequel[:tags][:name])
        .order(Sequel.lit('2 DESC'))
        .all
    end
  end
end
