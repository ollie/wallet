class TagsReport
  def monthly
    tags = Settings
           .database[:tags]
           .select(
             :name,
             :icon,
             :primary,
             Sequel.lit('sum(entries.amount)').as(:amount),
             Sequel.lit("date_trunc('month', COALESCE(entries.accounted_on, current_date))::date").as(:year_month)
           )
           .join(:taggings, tag_id: :id)
           .join(:entries, id: Sequel[:taggings][:entry_id])
           .group(Sequel[:tags][:id], Sequel.lit('5'))
           .order(Sequel.lit('5 DESC'), Sequel.lit('tags.primary DESC'), Sequel[:tags][:position])
           .all

    group_tags(tags)
  end

  def yearly
    tags = Settings
           .database[:tags]
           .select(
             :name,
             :icon,
             :primary,
             Sequel.lit('sum(entries.amount)').as(:amount),
             Sequel.lit("date_trunc('year', COALESCE(entries.accounted_on, current_date))::date").as(:year_month)
           )
           .join(:taggings, tag_id: :id)
           .join(:entries, id: Sequel[:taggings][:entry_id])
           .group(Sequel[:tags][:id], Sequel.lit('5'))
           .order(Sequel.lit('5 DESC'), Sequel.lit('tags.primary DESC'), Sequel[:tags][:position])
           .all

    group_tags(tags)
  end

  private

  def group_tags(tags)
    {}.tap do |years|
      previous_tag = nil

      tags.each do |tag|
        tag[:separator] = true if previous_tag && (previous_tag.fetch(:primary) && !tag.fetch(:primary))

        year_month = tag.fetch(:year_month)
        yearly_tags = years[year_month] ||= []
        yearly_tags << tag
        previous_tag = tag
      end
    end
  end
end
