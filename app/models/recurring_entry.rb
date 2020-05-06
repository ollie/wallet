class RecurringEntry < Sequel::Model
  #########
  # Plugins
  #########

  plugin :validation_helpers
  plugin :translated_validation_messages
  plugin :defaults_setter
  plugin :eager_each

  ###############
  # Class methods
  ###############

  def self.new_from_entry(entry)
    new.tap do |recurring_entry|
      recurring_entry.name = entry.note
      recurring_entry.amount = entry.amount
      recurring_entry.starts_on = Date.new(Date.today.year, entry.date.month, entry.date.day)
      recurring_entry.note    = entry.note
      recurring_entry.tag_ids = entry.tag_ids
    end
  end

  #################
  # Dataset methods
  #################

  dataset_module do
    def ordered
      order(:starts_on, :name)
    end

    def enabled
      where(enabled: true)
    end
  end

  #############
  # Validations
  #############

  def validate
    super

    validates_presence %i[
      name
      amount
      months_period
      starts_on
      note
    ]

    validates_includes [1, 12], :months_period
  end

  ###########
  # Callbacks
  ###########

  def before_validation
    self.note = name unless note.present?
    self.starts_on ||= Date.new(Date.today.year, 1, 1) if new?
  end

  def before_save
    self.tag_ids ||= []
    recurring_tag = Tag.first!(name: 'Pravidelné')
    tag_ids << recurring_tag.id unless tag_ids.include?(recurring_tag.id)
  end

  #########################
  # Public instance methods
  #########################

  def tags
    @tags ||= Tag.where(id: tag_ids.to_a).order(:position).to_a
  end
end
