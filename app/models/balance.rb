# TODO: Test all error messages nad translate them.
class Balance < Sequel::Model
  #########
  # Plugins
  #########

  plugin :validation_helpers
  plugin :translated_validation_messages

  #############
  # Validations
  #############

  def validate
    super

    validates_presence %i[
      amount
      year_month
    ]

    validates_format(/\A\d{4}-\d{2}\z/, :year_month)
  end

  #################
  # Dataset methods
  #################

  dataset_module do
    def ordered
      order(Sequel.desc(:year_month))
    end

    def data_for_chart
      incomes  = db[:entries].select(Sequel.lit('sum(amount)').as(:amount), Sequel.lit("date_trunc('month', accounted_on)::date").as(:year_month)).where(Sequel.lit('amount >= 0')).group(:year_month).order(:year_month).all
      expenses = db[:entries].select(Sequel.lit('sum(amount)').as(:amount), Sequel.lit("date_trunc('month', accounted_on)::date").as(:year_month)).where(Sequel.lit('amount < 0')).group(:year_month).order(:year_month).all
      balances = db[:balances].select(:amount, Sequel.lit(%[to_date("year_month", 'YYYY-MM')]).as(:year_month)).order(:year_month).all

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

    def by_date(date)
      month = date.strftime('%m')
      first(year_month: "#{date.year}-#{month}")
    end
  end

  #########################
  # Public instance methods
  #########################

  def year
    @year ||= date.year
  end

  def month
    @month ||= date.month
  end

  def date
    @date ||= Date.strptime(year_month, '%Y-%m')
  end
end
