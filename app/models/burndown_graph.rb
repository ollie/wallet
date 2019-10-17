class BurndownGraph
  attr_accessor :last_day_of_previous_month, :last_day_of_this_month, :previous_month_balance, :target_balance, :from, :to

  def initialize(date, previous_month_date)
    self.last_day_of_previous_month = Date.new(previous_month_date.year, previous_month_date.month, -1)
    self.last_day_of_this_month     = Date.new(date.year, date.month, -1)
    self.previous_month_balance     = Balance.by_date(last_day_of_previous_month)&.amount
    self.target_balance             = Balance.by_date(date)&.target_amount

    self.from = Date.new(date.year, date.month, 1)
    self.to   = Date.new(date.year, date.month, -1)
  end

  def data
    return [] unless previous_month_balance

    today   = Date.today
    data    = { last_day_of_previous_month => { balance: previous_month_balance } }
    balance = previous_month_balance.dup

    (from..to).each do |day|
      if day <= today
        amount   = expenses[day] || 0
        balance += amount

        data[day] = { balance: balance }
      else
        data[day] = { balance: nil } # Draw all days in current month
      end
    end

    fill_in_target_balances(data) if target_balance

    data.map do |day, hash|
      { date: day, balance: hash.fetch(:balance), target_balance: hash[:target_balance] }
    end
  end

  private

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

  def fill_in_target_balances(data)
    highest_balance_item = data.reject { |_day, hash| hash.fetch(:balance).nil? }.max_by { |_day, hash| hash.fetch(:balance) }

    highest_balance_day = highest_balance_item.first
    highest_balance     = highest_balance_item.last.fetch(:balance)

    days_range = highest_balance_day..to
    target_balance_decrease = (highest_balance - target_balance) / (days_range.last - days_range.first).to_i

    days_range.each.with_index do |day, i|
      balance =
        if day == last_day_of_this_month
          target_balance
        else
          balance = (highest_balance - target_balance_decrease * i).round(2) # * rand
          balance
        end

      data[day][:target_balance] = balance
    end
  end
end
