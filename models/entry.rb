# TODO: Test all error messages nad translate them.
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
    def by_month(date, sort_by: nil)
      sort_by ||= :accounted_on

      from = Date.new(date.year, date.month, 1)
      to   = Date.new(date.year, date.month, -1)

      ds = if date.year == Date.today.year && date.month == Date.today.month
             where(Sequel.lit('(:column BETWEEN :from AND :to OR :column IS NULL)', column: sort_by, from: from, to: to))
           else
             where(sort_by => from..to)
           end

      if sort_by == :date
        ds.order(Sequel.desc(:date), Sequel.desc(:accounted_on), Sequel.desc(:id))
      else
        ds.order(Sequel.desc(:accounted_on), Sequel.desc(:date), Sequel.desc(:id))
      end
    end

    def groupped_by_days(sort_by: nil)
      {}.tap do |days|
        eager(:tags).each do |entry|
          date = if sort_by == :date
                   entry.date
                 else
                   entry.accounted_on || Date.today
                 end

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
