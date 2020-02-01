module Charts
  class BurndownChart
    attr_accessor :last_day_of_previous_month, :last_day_of_this_month, :previous_month_balance, :target_balance, :today, :from, :to, :current_month

    def initialize(date, previous_month_date)
      self.last_day_of_previous_month = Date.new(previous_month_date.year, previous_month_date.month, -1)
      self.last_day_of_this_month     = Date.new(date.year, date.month, -1)
      self.previous_month_balance     = Balance.by_date(last_day_of_previous_month)&.amount
      self.target_balance             = Balance.by_date(date)&.target_amount

      self.today = Date.today
      self.from  = Date.new(date.year, date.month, 1)
      self.to    = Date.new(date.year, date.month, -1)

      start_of_month     = Date.new(today.year, today.month, 1)
      self.current_month = from == start_of_month
    end

    def data
      return [] unless previous_month_balance

      data = {
        last_day_of_previous_month => {
          balance: previous_month_balance,
          balance_with_unaccounted: previous_month_balance # Fixes first day of month not showing a line from last day of prev. month.
        }
      }

      balance = previous_month_balance.dup

      last_item_date = expenses.keys.last if current_month
      show_unaccounted = false

      (from..to).each do |day|
        if current_month && last_item_date && day <= last_item_date || day <= today
          amount   = expenses[day] || 0
          balance += amount

          balance_with_unaccounted =
            if day == today - 1
              balance
            elsif day == today
              new_balance = balance + (unaccounted_expenses[day] || 0)

              if new_balance != balance
                show_unaccounted = true

                # Removes first-day-of-month fix if we are in 2nd and on.
                if day.day != 1
                  data[last_day_of_previous_month][:balance_with_unaccounted] = nil
                end
              end

              new_balance
            else
              nil
            end

          data[day] = { balance: balance, balance_with_unaccounted: balance_with_unaccounted }
        else
          data[day] = { balance: nil } # Draw all days in current month
        end
      end

      fill_in_target_balances(data) if target_balance

      data.map do |day, hash|
        {
          date: day,
          balance: hash.fetch(:balance),
          balance_with_unaccounted: (hash[:balance_with_unaccounted] if show_unaccounted),
          target_balance: hash[:target_balance]
        }
      end
    end

    private

    def expenses
      @expenses ||= {}.tap do |hash|
        Settings
          .database[:entries]
          .select(Sequel.lit('accounted_on AS date, sum(amount) AS amount'))
          .where(Sequel.lit('accounted_on BETWEEN :from AND :to', from: from, to: to))
          .group(:accounted_on)
          .order(:accounted_on)
          .each { |item| hash[item.fetch(:date)] = item.fetch(:amount) }
      end
    end

    def unaccounted_expenses
      @unaccounted_expenses ||= {}.tap do |hash|
        Settings
          .database[:entries]
          .select(Sequel.lit('COALESCE(accounted_on, current_date) AS date, sum(amount) AS amount'))
          .where(accounted_on: nil)
          .group(Sequel.lit('COALESCE(accounted_on, current_date)'))
          .order(Sequel.lit('COALESCE(accounted_on, current_date)'))
          .each { |item| hash[item.fetch(:date)] = item.fetch(:amount) }
      end
    end

    def fill_in_target_balances(data)
      highest_balance_item = data.reject { |_day, hash| hash.fetch(:balance).nil? }.max_by { |_day, hash| hash.fetch(:balance) }

      highest_balance_day = highest_balance_item.first
      highest_balance     = highest_balance_item.last.fetch(:balance)

      return if highest_balance < target_balance

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
end
