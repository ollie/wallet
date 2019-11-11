module Charts
  class BalancesChart
    def data
      incomes  = Settings.database[:entries].select(Sequel.lit('sum(amount)').as(:amount), Sequel.lit("date_trunc('month', accounted_on)::date").as(:year_month)).where(Sequel.lit('amount >= 0')).group(:year_month).order(:year_month).all
      expenses = Settings.database[:entries].select(Sequel.lit('sum(amount)').as(:amount), Sequel.lit("date_trunc('month', accounted_on)::date").as(:year_month)).where(Sequel.lit('amount < 0')).group(:year_month).order(:year_month).all
      balances = Settings.database[:balances].select(:amount, :target_amount, Sequel.lit(%[to_date("year_month", 'YYYY-MM')]).as(:year_month)).order(:year_month).all

      current_target_balance = balances.last[:target_amount]

      balances.map.with_index do |balance, i|
        balance[:incomes]  = 0.to_d
        balance[:expenses] = 0.to_d

        if incomes.any? && incomes.first[:year_month] == balance[:year_month]
          balance[:incomes] = incomes.shift[:amount]
        end

        if expenses.any? && expenses.first[:year_month] == balance[:year_month]
          balance[:expenses] = expenses.shift[:amount]
        end

        if current_target_balance
          balance[:target] = balance[:amount]       unless balances[i + 2]
          balance[:target] = current_target_balance unless balances[i + 1]
        end

        {
          date:     balance[:year_month],
          total:    balance[:amount],
          target:   balance[:target],
          incomes:  balance[:incomes],
          expenses: -balance[:expenses]
        }
      end
    end
  end
end
