# TODO: Test all error messages and translate them.
class Entry < Sequel::Model
  #########
  # Plugins
  #########

  plugin :validation_helpers
  plugin :translated_validation_messages
  plugin :eager_each

  ##############
  # Associations
  ##############

  many_to_many :tags, join_table: :taggings, order: :position
  many_to_many :primary_tags, class: :Tag, join_table: :taggings, right_key: :tag_id, order: :position do |ds|
    ds.where(primary: true)
  end

  #################
  # Dataset methods
  #################

  dataset_module do
    def by_month(date)
      from = Date.new(date.year, date.month, 1)
      to   = Date.new(date.year, date.month, -1)

      ds = where(Sequel.lit('COALESCE(accounted_on, current_date) BETWEEN :from AND :to', from: from, to: to))
      ds.order(Sequel.desc(Sequel.lit('COALESCE(accounted_on, current_date)')), Sequel.desc(:date), Sequel.desc(:id))
    end

    def groupped_by_days
      {}.tap do |days|
        eager(:tags).each do |entry|
          date = entry.accounted_on || Date.today

          day = days[date] ||= []
          day << entry
        end
      end
    end

    def incomes
      where { amount > 0 }
    end

    def expenses
      where { amount < 0 }
    end

    def incomes_sum
      incomes.sum(:amount) || 0
    end

    def expenses_sum
      expenses.sum(:amount) || 0
    end
  end

  #############
  # Validations
  #############

  def validate
    super

    validates_presence [
      :amount,
      :date
    ]
  end

  #########################
  # Public instance methods
  #########################

  def prepare_for_duplication
    today = Date.today

    self.date =
      begin
        today
      rescue ArgumentError
        Date.new(today.year, today.month, -1)
      end

    self.accounted_on =
      begin
        today
      rescue ArgumentError
        Date.new(today.year, today.month, -1)
      end
  end

  def save_and_handle_tags(params)
    save
    setup_tags(params)
  end

  def setup_tags(params)
    params_tag_ids = params.dig(:entry, :tag_ids)&.map(&:to_i) || []

    if new?
      params_tag_ids.each { |tag_id| add_tag(tag_id) }
    else
      entry_tag_ids     = tags_dataset.select_map(:id)
      tag_ids_to_add    = params_tag_ids - entry_tag_ids
      tag_ids_to_remove = entry_tag_ids - params_tag_ids

      tag_ids_to_add.each    { |tag_id| add_tag(tag_id) }
      tag_ids_to_remove.each { |tag_id| remove_tag(tag_id) }
    end
  end
end
