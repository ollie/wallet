desc 'Export data s JSON and .dump'
task export: ['export:json_export', 'export:db_export']

namespace :export do
  desc 'Export data as JSON'
  task json_export: :environment do
    data = {}

    data['balances'] = Balance.order(:id).map do |balance|
      {
        # id:         balance.id,
        amount:     balance.amount,
        year_month: balance.year_month,
        note:       balance.note
      }
    end

    data['tags'] = Tag.order(:id).map do |tag|
      {
        # id:       tag.id,
        name:     tag.name,
        color:    tag.color,
        position: tag.position,
        primary:  tag.primary
      }
    end

    data['entries'] = Entry.order(:id).map do |entry|
      {
        # id:           entry.id,
        amount:       entry.amount,
        date:         entry.date,
        accounted_on: entry.accounted_on,
        note:         entry.note,
        tags:         entry.tags_dataset.order(:id).select_map(:name)
      }
    end

    mkdir_p 'data'
    file = 'data/data.json'

    if File.file?(file)
      mv file, "data/data-#{Time.now.strftime('%Y%m%d-%H%M%S')}.json"
    end

    File.write(file, JSON.pretty_generate(data))
    puts file
  end

  desc 'Import data as JSON'
  task json_import: :environment do
    file = 'data/data.json'
    abort 'There is nothing to import.' unless File.file?(file)

    data = JSON.load(File.read(file))

    Settings.database[:balances].truncate(restart: true)
    Settings.database[:tags].truncate(cascade: true, restart: true)
    Settings.database[:entries].truncate(cascade: true, restart: true)

    data['balances'].each do |item|
      Balance.create(item)
    end

    data['tags'].each do |item|
      item['id'] = Tag.create(item).id
    end

    data['entries'].each do |item|
      tag_names = item.delete('tags')
      entry     = Entry.create(item)

      tag_names.each do |tag_name|
        tag_id = data['tags'].find { |tag| tag['name'] == tag_name }.fetch('id')
        entry.add_tag(tag_id)
      end
    end
  end

  desc 'Export database as .dump'
  task db_export: :environment do
    db        = Settings.database_url.split('/').last
    dump_path = "data/data-#{Time.now.strftime('%Y%m%d-%H%M%S')}.dump"

    sh "pg_dump -Fc -c #{db} > #{dump_path}"
  end

  desc 'Import .dump database'
  task db_import: :environment do
    db        = Settings.database_url.split('/').last
    dump_path = Dir['data/data-*.dump'].sort.last

    abort 'No dump found' unless dump_path

    sh "pg_restore -c -d #{db} #{dump_path}"
  end
end
