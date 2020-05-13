module Charts
  class RecurringEntriesChart
    attr_accessor :date, :next_year, :months_data

    def initialize(date: Date.today, next_year: false)
      self.date        = Date.new(date.year, date.month, 1)
      self.next_year   = next_year
      self.months_data = {}

      1.upto(12).each do |n|
        months_data[Date.new(date.year, n, 1)] = {
          remainder: 0.to_d,
          incomes: 0.to_d,
          expenses: 0.to_d,
          balance: 0.to_d
        }
      end

      return unless next_year

      1.upto(12).each do |n|
        months_data[Date.new(date.year + 1, n, 1)] = {
          remainder: 0.to_d,
          incomes: 0.to_d,
          expenses: 0.to_d,
          balance: 0.to_d
        }
      end
    end

    def data
      recurring_entries =
        Settings
        .database[:recurring_entries]
        .select(Sequel.lit("months_period, amount, date_trunc('month', starts_on)::date AS starts_on, date_trunc('month', ends_on)::date AS ends_on"))
        .where(enabled: true)
        .where(Sequel.lit('ends_on IS NULL OR ends_on >= ?', Date.new(date.year, 1, 1)))
        .order(:months_period, :starts_on)

      recurring_entries = recurring_entries.where(Sequel.lit('starts_on <= ?', Date.new(date.year, 12, 31))) unless next_year

      recurring_entries.each do |recurring_entry|
        month_date = recurring_entry.fetch(:starts_on)
        amount     = recurring_entry.fetch(:amount)

        add_amount(month_date, amount)

        loop do
          month_date = month_date >> recurring_entry.fetch(:months_period)

          break if next_year && month_date.year > date.year + 1
          break if !next_year && month_date.year > date.year
          break if recurring_entry.fetch(:ends_on) && month_date >= recurring_entry.fetch(:ends_on)

          add_amount(month_date, amount)
        end
      end

      calculate_remainders
      months_data
    end

    private

    def add_amount(month_date, amount)
      if amount < 0
        months_data[month_date][:expenses] += -amount
      else
        months_data[month_date][:incomes] += amount
      end
    end

    def calculate_remainders
      balances = {}

      Balance.where(Sequel.lit('year_month LIKE ?', "#{date.year}-%")).order(:year_month).each do |balance|
        balances[balance.date] = balance.amount
      end

      predicted_balance = nil

      months_data.each do |month_date, hash|
        remainder = hash.fetch(:incomes) - hash.fetch(:expenses)
        remainder = 0.to_d if remainder < 0

        if month_date == date
          predicted_balance = Balance.by_date(date.prev_month)&.amount
        end

        predicted_balance += remainder if predicted_balance

        hash[:remainder]         = remainder
        hash[:predicted_balance] = predicted_balance
        hash[:balance]           = balances[month_date]
      end
    end
  end
end
