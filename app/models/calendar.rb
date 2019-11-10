module Calendar
  extend self

  def years
    [].tap do |array|
      data = Settings
             .database[:entries]
             .select(Sequel.lit("date_trunc('month', COALESCE(accounted_on, current_date))::date AS date, count(*)"))
             .group(Sequel.lit('1'))
             .order(Sequel.lit('1 DESC'))
             .all

      if data.any?
        month_map = {}
        data.each { |entry| month_map[entry.fetch(:date)] = entry.fetch(:count) }

        last_year  = data.first.fetch(:date).year
        first_year = data.last.fetch(:date).year

        last_year.downto(first_year).each do |year|
          array << [
            year,
            (1..3).map do |row|
              (1..4).map do |cell|
                month = 13 - ((row - 1) * 4 + cell)
                date  = Date.new(year, month, 1)

                {
                  date:          date,
                  entries_count: month_map[date] || 0
                }
              end
            end
          ]
        end
      end
    end
  end
end
