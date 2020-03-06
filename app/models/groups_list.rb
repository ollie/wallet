class GroupsList
  attr_accessor :groups, :count, :incomes, :expenses, :dataset

  class << self
    def by_month(date)
      new.tap do |groups_list|
        data(date: date).each do |entry|
          add_entry(groups_list, entry)
        end
      end
    end

    def by_month_and_tag(date, tag: nil)
      new.tap do |groups_list|
        data(date: date, tag: tag).each do |entry|
          add_entry(groups_list, entry)
        end
      end
    end

    def search(phrases, date_from, date_to, page)
      new.tap do |groups_list|
        ds = data(phrases: phrases, date_from: date_from, date_to: date_to, page: page, per_page: 20)
        groups_list.dataset = ds
        ds.each do |entry|
          add_entry(groups_list, entry)
        end
      end
    end

    private

    def add_entry(groups_list, entry)
      entry = Entry.new(entry)
      day = groups_list.groups[entry.accounted_on] ||= Group.new
      day.entries << entry
      day.total += entry.amount

      groups_list.count    += 1
      groups_list.incomes  += entry.amount if entry.amount > 0
      groups_list.expenses += entry.amount if entry.amount < 0
    end
  end

  def initialize
    self.groups   = {}
    self.count    = 0
    self.incomes  = 0
    self.expenses = 0
  end

  class Group
    attr_accessor :entries, :total

    def initialize
      self.entries = []
      self.total   = 0
    end
  end

  class Entry
    attr_accessor :id, :amount, :date, :accounted_on, :pending, :note, :tags

    def initialize(hash)
      self.id           = hash.fetch(:id)
      self.amount       = hash.fetch(:amount)
      self.date         = hash.fetch(:date)
      self.accounted_on = hash.fetch(:accounted_on)
      self.pending      = hash.fetch(:pending)
      self.note         = hash.fetch(:note)
      self.tags         = (hash.fetch(:tags) || []).map { |array| Tag.new(array) }
    end
  end

  class Tag
    attr_accessor :id, :name, :icon, :color

    def initialize(array)
      self.id    = array.fetch(0)
      self.name  = array.fetch(1)
      self.icon  = array.fetch(2)
      self.color = array.fetch(3)
    end

    def color_for_text_or_icon
      if icon
        '#ffffff'
      else
        color
      end
    end

    def dark?
      return @is_dark if defined?(@is_dark)
      return @is_dark = false unless color

      @is_dark = ::Tag.dark_background?(color)
    end

    def light?
      return @is_light if defined?(@is_light)
      return @is_light = false unless color

      @is_light = !dark?
    end
  end

  def self.data(date: nil, tag: nil, phrases: nil, date_from: nil, date_to: nil, page: nil, per_page: nil)
    if date
      from = Date.new(date.year, date.month, 1)
      to   = Date.new(date.year, date.month, -1)
    end

    ds = Settings
         .database[:entries]
         .select(
           Sequel[:entries].*,
           Sequel.function(:coalesce, :accounted_on, Sequel.lit('current_date')).as(:accounted_on),
           Sequel.case({ { Sequel[:entries][:accounted_on] => nil } => false }, true).as(:pending),
           Sequel.lit('array_agg(ARRAY[tags.id::text, tags.name, tags.icon, tags.color] ORDER BY tags.position) FILTER (WHERE tags.id IS NOT NULL)').as(:tags)
         )
         .left_join(:taggings, entry_id: :id)
         .left_join(:tags, id: Sequel[:taggings][:tag_id])
         .group(Sequel[:entries][:id])
         .order(
           Sequel.function(:coalesce, :accounted_on, Sequel.lit('current_date')).desc,
           Sequel[:entries][:date].desc,
           Sequel[:entries][:id].desc
         )
    ds = ds.where(Sequel.function(:coalesce, :accounted_on, Sequel.lit('current_date')) => from..to) if date
    ds = ds.where(Sequel.lit('COALESCE(accounted_on, current_date) >= ?', date_from)) if date_from
    ds = ds.where(Sequel.lit('COALESCE(accounted_on, current_date) <= ?', date_to))   if date_to
    ds = ds.where(Sequel.ilike(:note, *phrases.map { |phrase| "%#{phrase}%" })) if phrases && phrases.any?
    ds = ds.where(Sequel.lit('EXISTS (SELECT 1 FROM taggings WHERE taggings.entry_id = entries.id AND taggings.tag_id = ?)', tag.id)) if tag
    ds = ds.extension(:pagination).paginate(page, per_page) if page
    ds
  end
end
