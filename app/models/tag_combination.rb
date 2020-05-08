class TagCombination < Sequel::Model
  #########
  # Plugins
  #########

  plugin :validation_helpers
  plugin :translated_validation_messages
  plugin :defaults_setter
  plugin :eager_each

  #################
  # Dataset methods
  #################

  dataset_module do
    def ordered
      order(:position)
    end
  end

  #############
  # Validations
  #############

  def validate
    super

    validates_presence %i[
      tag_ids
    ]
  end

  ###########
  # Callbacks
  ###########

  def before_create
    self.position ||= begin
      (model.ordered.select(:position).last&.position || 0) + 1
    end

    super
  end

  #########################
  # Public instance methods
  #########################

  def tags
    @tags ||= Tag.where(id: tag_ids.to_a).order(:position).to_a
  end
end
