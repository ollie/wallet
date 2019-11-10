module Charts
  class BalancesChart
    def data
      incomes  = Settings.database[:entries].select(Sequel.lit('sum(amount)').as(:amount), Sequel.lit("date_trunc('month', accounted_on)::date").as(:year_month)).where(Sequel.lit('amount >= 0')).group(:year_month).order(:year_month).all
      expenses = Settings.database[:entries].select(Sequel.lit('sum(amount)').as(:amount), Sequel.lit("date_trunc('month', accounted_on)::date").as(:year_month)).where(Sequel.lit('amount < 0')).group(:year_month).order(:year_month).all
      balances = Settings.database[:balances].select(:amount, Sequel.lit(%[to_date("year_month", 'YYYY-MM')]).as(:year_month)).order(:year_month).all

      balances.map do |balance|
        balance[:incomes]  = 0.to_d
        balance[:expenses] = 0.to_d

        if incomes.any? && incomes.first[:year_month] == balance[:year_month]
          balance[:incomes] = incomes.shift[:amount]
        end

        if expenses.any? && expenses.first[:year_month] == balance[:year_month]
          balance[:expenses] = expenses.shift[:amount]
        end

        {
          date:     balance[:year_month],
          total:    balance[:amount],
          incomes:  balance[:incomes],
          expenses: -balance[:expenses]
        }
      end
    end
  end
end
