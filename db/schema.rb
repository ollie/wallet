Sequel.migration do
  change do
    create_table(:balances) do
      primary_key :id
      column :amount, 'numeric(11,2)', null: false
      column :year_month, 'character varying(7)', null: false
      column :note, 'character varying(255)'
      column :target_amount, 'numeric(11,2)'

      index [:year_month], unique: true
    end

    create_table(:entries) do
      primary_key :id
      column :amount, 'numeric(10,2)', null: false
      column :date, 'date', null: false
      column :accounted_on, 'date'
      column :note, 'character varying(255)'

      index [:accounted_on]
      index [:amount]
      index [:date]
    end

    create_table(:schema_info) do
      column :version, 'integer', default: 0, null: false
    end

    create_table(:tags) do
      primary_key :id
      column :name, 'character varying(255)', null: false
      column :color, 'character varying(7)'
      column :position, 'integer'
      column :entries_count, 'integer', default: 0, null: false
      column :primary, 'boolean', default: false, null: false
      column :icon, 'character varying(40)'

      index [:name], unique: true
    end

    create_table(:taggings) do
      foreign_key :tag_id, :tags, null: false, key: [:id], on_delete: :cascade
      foreign_key :entry_id, :entries, null: false, key: [:id], on_delete: :cascade

      primary_key %i[tag_id entry_id]

      index [:entry_id]
      index [:tag_id]
    end
  end
end
