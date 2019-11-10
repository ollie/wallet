module Charts
  class TagEntriesChart
    attr_accessor :tag_id, :date

    def initialize(tag_id:, date:)
      self.tag_id = tag_id
      self.date   = date
    end

    def data
      ds = Tag.with_pk!(tag_id).entries_dataset
      to = Date.new(date.year, date.month, -1)
      ds.where(Sequel.lit('COALESCE(accounted_on, current_date) <= :to', to: to))
      ds = ds.select(Sequel.lit('sum(amount)').as(:amount), Sequel.lit("date_trunc('month', COALESCE(accounted_on, current_date))::date").as(:year_month))

      incomes  = ds.where(Sequel.lit('amount >= 0')).group(:year_month).order(:year_month).all
      expenses = ds.where(Sequel.lit('amount < 0')).group(:year_month).order(:year_month).all

      start_date = [(incomes.first && incomes.first[:year_month]), (expenses.first && expenses.first[:year_month])].compact.min

      return [] unless start_date

      end_date = Date.new(date.year, date.month, 1)

      date = start_date
      data = []

      loop do
        item_incomes =
          if incomes.first && incomes.first[:year_month] == date
            incomes.shift[:amount]
          else
            0.to_d
          end

        item_expenses =
          if expenses.first && expenses.first[:year_month] == date
            expenses.shift[:amount]
          else
            0.to_d
          end

        item_total = item_incomes + item_expenses

        item = {
          date:     date,
          total:    item_total,
          incomes:  item_incomes,
          expenses: -item_expenses
        }

        data << item

        break if date == end_date

        date = date.next_month
      end

      if data.all? { |i| i[:incomes] == 0 }
        data.each do |i|
          i.delete(:total)
          i.delete(:incomes)
        end
      end

      if data.all? { |i| i[:expenses] == 0 }
        data.each do |i|
          i.delete(:total)
          i.delete(:expenses)
        end
      end

      data
    end
  end
end
