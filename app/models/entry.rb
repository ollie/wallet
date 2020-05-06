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

  ###############
  # Class methods
  ###############

  def self.new_from_entry(other_entry)
    new.tap do |entry|
      entry.amount = other_entry.amount
      today = Date.today

      entry.date =
        begin
          today
        rescue ArgumentError
          Date.new(today.year, today.month, -1)
        end

      entry.note    = other_entry.note
      entry.tag_ids = other_entry.tag_ids
    end
  end

  def self.new_from_recurring_entry(recurring_entry)
    new.tap do |entry|
      entry.amount  = recurring_entry.amount
      entry.date    = Date.today
      entry.note    = recurring_entry.note
      entry.tag_ids = recurring_entry.tag_ids
    end
  end

  #############
  # Validations
  #############

  def validate
    super

    validates_presence %i[
      amount
      date
    ]
  end

  #########################
  # Public instance methods
  #########################

  def tag_ids
    @tag_ids ||=
      if new?
        []
      else
        tags_dataset.select_map(:id)
      end
  end

  def tag_ids=(ids)
    @tag_ids = (ids || []).map(&:to_i)
  end

  def save_and_handle_tags
    db.transaction do
      save
      add_or_remove_tags
    end
  end

  def add_or_remove_tags
    if new?
      tag_ids.each { |tag_id| add_tag(tag_id) }
    else
      saved_tag_ids     = tags_dataset.select_map(:id)
      tag_ids_to_add    = tag_ids - saved_tag_ids
      tag_ids_to_remove = saved_tag_ids - tag_ids

      tag_ids_to_add.each    { |tag_id| add_tag(tag_id) }
      tag_ids_to_remove.each { |tag_id| remove_tag(tag_id) }
    end
  end
end
