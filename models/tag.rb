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

  ###############
  # Class methods
  ###############

  class << self
    def most_used_combinations
      groups = db.fetch(
        <<~END
          WITH combinations AS (
            SELECT array_agg(tag_id ORDER BY tag_id) AS tag_ids
            FROM taggings
            GROUP BY entry_id
          )

          SELECT tag_ids
          FROM combinations
          GROUP BY tag_ids
          ORDER BY count(*) DESC
        END
      ).map { |item| item[:tag_ids] }

      tag_ids = Set.new
      groups.each { |group| group.each { |tag_id| tag_ids << tag_id } }
      tags = Tag.where(id: tag_ids.to_a).all
      index = {}
      tags.each { |tag| index[tag.id] = tag }

      groups = groups.map { |group| group.map { |tag_id| index[tag_id] } }
      groups.each { |group| group.sort! { |a, b| a.position <=> b.position } }
    end
  end

  #########################
  # Public instance methods
  #########################

  def dark?
    return @is_dark if defined?(@is_dark)
    return @is_dark = false unless color
    parts = color.delete('#').scan(/.{2}/).map { |s| s.to_i(16) }
    @is_dark = parts.reduce(:+) < 255 * 2
  end

  def light?
    return @is_light if defined?(@is_light)
    return @is_light = false unless color
    @is_light = !dark?
  end

  #################
  # Dataset methods
  #################

  dataset_module do
    def ordered
      order(:position)
    end
  end
end
