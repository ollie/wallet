class Balance < Sequel::Model
  #########
  # Plugins
  #########

  plugin :validation_helpers

  #############
  # Validations
  #############

  def validate
    super

    validates_presence [
      :amount,
      :year_month
    ]

    validates_format(/\A\d{4}-\d{2}\z/, :year_month)
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

  #################
  # Dataset methods
  #################

  dataset_module do
    def ordered
      order(Sequel.desc(:year_month))
    end

    def by_date(date)
      month = format('%02d', date.month)
      first(year_month: "#{date.year}-#{month}")
    end
  end
end
