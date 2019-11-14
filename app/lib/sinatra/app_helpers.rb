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

    def pagination_pages(dataset)
      pages        = []
      outer_window = 1
      inner_window = 2

      inner_window_start = dataset.current_page - inner_window
      inner_window_start = 1 if inner_window_start < 1
      inner_window_end   = dataset.current_page + inner_window
      inner_window_end   = dataset.page_count if inner_window_end > dataset.page_count
      inner_window_range = inner_window_start..inner_window_end

      if inner_window_start >= 1 + outer_window - 1
        prev_outer_window_start = 1
        prev_outer_window_end   = 1 + outer_window - 1
        prev_outer_window_end   = inner_window_start - 1 if prev_outer_window_end >= inner_window_start
        prev_outer_window_range = prev_outer_window_start..prev_outer_window_end
      end

      if inner_window_end <= dataset.page_count - outer_window + 1
        next_outer_window_start = dataset.page_count - outer_window + 1
        next_outer_window_start = inner_window_end + 1 if next_outer_window_start <= inner_window_end
        next_outer_window_end   = dataset.page_count
        next_outer_window_range = next_outer_window_start..next_outer_window_end
      end

      pages << :prev unless dataset.first_page?

      if prev_outer_window_range
        prev_outer_window_range.each do |page|
          pages << page if page < inner_window_start
        end

        pages << :separator if inner_window_start - prev_outer_window_end > 1
      end

      inner_window_range.each do |page|
        pages <<
          if page == dataset.current_page
            [page, true]
          else
            page
          end
      end

      if next_outer_window_range
        pages << :separator if next_outer_window_start - inner_window_end > 1

        next_outer_window_range.each do |page|
          pages << page if page > inner_window_end
        end
      end

      pages << :next unless dataset.last_page?

      pages
    end
  end
end
