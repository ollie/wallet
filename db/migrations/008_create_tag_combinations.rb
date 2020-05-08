Sequel.migration do
  change do
    create_table :tag_combinations do
      primary_key :id

      column :tag_ids, 'integer[]', null: false
      Integer :position
    end
  end
end
