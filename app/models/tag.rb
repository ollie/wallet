# TODO: Test all error messages nad translate them.
class Tag < Sequel::Model
  #########
  # Plugins
  #########

  plugin :validation_helpers
  plugin :translated_validation_messages
  plugin :defaults_setter
  plugin :eager_each

  ##############
  # Associations
  ##############

  many_to_many :entries, join_table: :taggings

  ###############
  # Class methods
  ###############

  class << self
    def dark_background?(color)
      parts = color.delete('#').scan(/.{2}/).map { |s| s.to_i(16) }
      parts.reduce(:+) < 255 * 2
    end

    def light_background?(color)
      !dark_background?(color)
    end
  end

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

    validates_presence [
      :name
    ]

    validates_unique :name
    validates_exact_length 7, :color, allow_nil: true
  end

  ###########
  # Callbacks
  ###########

  def before_validation
    # Hack to circumvent the fact that input type color cannot be empty.
    self.color = nil if color == '#000000'

    super
  end

  def before_create
    self.position ||= begin
      (model.ordered.select(:position).last&.position || 0) + 1
    end

    super
  end

  #########################
  # Public instance methods
  #########################

  def color_for_text_or_icon
    if icon.present?
      '#ffffff'
    else
      color
    end
  end

  def dark?
    return @is_dark if defined?(@is_dark)
    return @is_dark = false unless color

    @is_dark = self.class.dark_background?(color)
  end

  def light?
    return @is_light if defined?(@is_light)
    return @is_light = false unless color

    @is_light = !dark?
  end
end
