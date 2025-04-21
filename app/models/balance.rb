# TODO: Test all error messages nad translate them.
class Balance < Sequel::Model
  #########
  # Plugins
  #########

  plugin :paginate
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

    def by_date(date)
      month = date.strftime('%m')

      if Settings.privacy_mode?
        model.new(amount: 100_000, year_month: "#{date.year}-#{month}").tap do |instance|
          def instance.id
            1
          end
        end
      else
        month = date.strftime('%m')
        first(year_month: "#{date.year}-#{month}")
      end
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
