module Sinatra
  module AppHelpers
    def pagination_date
      @pagination_date ||= begin
        year  = params[:year]&.to_i  || Date.today.year
        month = params[:month]&.to_i || Date.today.month

        Date.new(year, month)
      end
    end

    def previous_month(from_date = pagination_date)
      @previous_month ||= begin
        if from_date.month == 1
          Date.new(from_date.year - 1, 12)
        else
          Date.new(from_date.year, from_date.month - 1)
        end
      end
    end

    def next_month
      return @next_month if defined?(@next_month)

      @next_month = nil

      return @next_month if this_or_future_month?(pagination_date)

      next_month = if pagination_date.month == 12
                     Date.new(pagination_date.year + 1, 1)
                   else
                     Date.new(pagination_date.year, pagination_date.month + 1)
                   end

      @next_month = next_month
    end

    def this_or_future_month?(date)
      today = Date.today
      date.year > today.year || date.year == today.year && date.month >= today.month
    end

    def this_month?(date)
      today = Date.today
      date.year == today.year && date.month == today.month
    end

    def prefilled_date(date)
      return date if date

      today = Date.today

      if pagination_date.year == today.year && pagination_date.month == today.month
        nil
      elsif pagination_date < today
        Date.new(pagination_date.year, pagination_date.month, -1)
      end
    end

    def entry_year_month_qs_params(entry)
      date = entry.accounted_on || pagination_date

      {
        year:  date.year,
        month: date.month
      }
    end

    def formatted_amount(amount, plus: true, format: '%+.02f')
      format = '%.02f' unless plus
      format(format, amount).tap do |s|
        s.gsub!(/(\d)(?=(\d{3})+(?!\d))/, '\1 ')
        s.tr!('.', ',')
        s << ' Kč'
        s.gsub!(' ', '&nbsp;')
      end
    end

    def formatted_date(date)
      l(date).gsub!(' ', '&nbsp;')
    end
  end
end