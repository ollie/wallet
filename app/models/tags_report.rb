class TagsReport
  def data
    tags = Settings
      .database[:tags]
      .select(
        :name,
        :icon,
        Sequel.lit('sum(entries.amount)').as(:amount),
        Sequel.lit("date_trunc('month', COALESCE(entries.accounted_on, current_date))::date").as(:year_month)
      )
      .join(:taggings, tag_id: :id)
      .join(:entries, id: Sequel[:taggings][:entry_id])
      .where(Sequel[:tags][:primary] => true)
      .group(Sequel[:tags][:id], Sequel.lit('4'))
      .order(Sequel.lit('4 DESC'), Sequel[:tags][:position])
      .all

    {}.tap do |years|
      tags.each do |tag|
        year_month = tag.fetch(:year_month)
        yearly_tags = years[year_month] ||= []
        yearly_tags << tag
      end
    end
  end
end
