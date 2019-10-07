class BurndownGraph
  attr_accessor :last_day_of_previous_month, :previous_month_balance, :from, :to

  def initialize(date, previous_month_date)
    self.last_day_of_previous_month = Date.new(previous_month_date.year, previous_month_date.month, -1)
    self.previous_month_balance     = Balance.by_date(last_day_of_previous_month).amount

    self.from = Date.new(date.year, date.month, 1)
    self.to   = Date.new(date.year, date.month, -1)
  end

  def data
    today   = Date.today
    data    = { last_day_of_previous_month => previous_month_balance }
    balance = previous_month_balance.dup

    (from..to).each do |day|
      if day <= today
        amount   = expenses[day] || 0
        balance += amount

        data[day] = balance
      else
        data[day] = nil # Draw all days in current month
      end
    end

    data.map do |day, amount|
      { date: day, balance: amount }
    end
  end

  def expenses
    @expenses ||= {}.tap do |hash|
      Settings
        .database[:entries]
        .select(Sequel.lit('COALESCE(accounted_on, current_date) AS date, sum(amount) AS amount'))
        .where(Sequel.lit('COALESCE(accounted_on, current_date) BETWEEN :from AND :to', from: from, to: to))
        .group(Sequel.lit('COALESCE(accounted_on, current_date)'))
        .order(Sequel.lit('COALESCE(accounted_on, current_date)'))
        .each { |item| hash[item.fetch(:date)] = item.fetch(:amount) }
    end
  end
end
