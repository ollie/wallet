Sequel.migration do
  change do
    create_table :taggings do
      primary_key [:tag_id, :entry_id]

      foreign_key :tag_id,   :tags,    on_delete: :cascade
      foreign_key :entry_id, :entries, on_delete: :cascade

      index :tag_id
      index :entry_id
    end

    pgt_counter_cache :tags, :id, :entries_count, :taggings, :tag_id
  end
end
