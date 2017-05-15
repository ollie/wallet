Sequel.migration do
  change do
    create_table :tags do
      primary_key :id

      String :name, size: 255, null: false
      String :color, size: 7
      Integer :position
      Integer :entries_count, null: false, default: 0
      FalseClass :primary, null: false, default: false

      index :name, unique: true
    end
  end
end
