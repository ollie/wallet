module Sinatra
  module AppHelpers
    def pagination_date
      @pagination_date ||= begin
        year  = params[:year]&.to_i  || Date.today.year
        month = params[:month]&.to_i || Date.today.month

        Date.new(year, month)
      end
    end

    def previous_month
      @previous_month ||= begin
        if pagination_date.month == 1
          Date.new(pagination_date.year - 1, 12)
        else
          Date.new(pagination_date.year, pagination_date.month - 1)
        end
      end
    end

    def next_month
      return @next_month if defined?(@next_month)

      @next_month = nil
      today = Date.today

      return @next_month if pagination_date.year > today.year || pagination_date.year == today.year && pagination_date.month >= today.month

      next_month = if pagination_date.month == 12
                     Date.new(pagination_date.year + 1, 1)
                   else
                     Date.new(pagination_date.year, pagination_date.month + 1)
                   end

      @next_month = next_month
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
        s.reverse!
        s.gsub!(/(\d{3})(\d)/, '\1 \2')
        s.tr!('.', ',')
        s.reverse!
        s << ' Kč'
        s.gsub!(' ', '&nbsp;')
      end
    end

    def formatted_date(date)
      l(date).gsub!(' ', '&nbsp;')
    end
  end
end
