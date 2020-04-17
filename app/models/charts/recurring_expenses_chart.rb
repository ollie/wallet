module Charts
  class RecurringExpensesChart

    attr_accessor :date

    def initialize(date)
      self.date = date
    end

    def data
      period_end            = Date.new(date.year, 12, 31)
      period_start          = Date.new(date.year - 2, 1, 1)
      previous_period_end   = Date.new(date.year - 1, 12, 31)
      previous_period_start = Date.new(date.year - 3, 1, 1)

      # TODO: Add flag to Pravidelne tag.
      period_expenses          = fetch_expenses(period_start, period_end)
      previous_period_expenses = fetch_expenses(previous_period_start, previous_period_end)

      previous_period_expenses.zip(period_expenses).map do |previous_period_expense, period_expense|
        {
          date: period_expense.fetch(:date),
          previous_period_expenses: previous_period_expense.fetch(:expenses),
          expenses: period_expense.fetch(:expenses)
        }
      end
    end

    private

    def fetch_expenses(from, to)
      Settings
        .database
        .from(Sequel.lit("generate_series(?::date, ?::date, '1 month') AS month", from, to))
        .select(
          Sequel.lit('month::date').as(:date),
          Sequel.lit('entries_by_month.expenses').as(:expenses)
        )
        .left_join(
          Settings
            .database[:entries]
            .select(
              Sequel.lit("date_trunc('month', entries.date)").as(:date),
              Sequel.lit('-sum(entries.amount)').as(:expenses)
            )
            .join(:taggings, entry_id: :id)
            .join(:tags, id: Sequel[:taggings][:tag_id], name: 'Pravidelné')
            .where(Sequel[:entries][:date] => from..to)
            .where(Sequel.lit('entries.amount < 0'))
            .group(Sequel.lit('1'))
            .order(Sequel.lit('1'))
            .as(:entries_by_month),
          Sequel.lit('entries_by_month.date = month')
        )
        .all
    end
  end
end
