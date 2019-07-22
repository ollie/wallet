module Calendar
  extend self

  def years
    [].tap do |array|
      this_year  = Date.today.year
      first_year = Entry.order(:accounted_on).first.accounted_on.year

      this_year.downto(first_year).each do |year|
        array << [
          year,
          (1..3).map do |row|
            (1..4).map do |cell|
              month = (row - 1) * 4 + cell
              from  = Date.new(year, month, 1)
              to    = Date.new(year, month, -1)

              {
                date: from,
                entries_count: Entry.where(accounted_on: from..to).count
              }
            end
          end
        ]
      end
    end
  end
end
