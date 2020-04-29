Sequel.migration do
  change do
    create_table :recurring_entries do
      primary_key :id

      String :name, size: 255, null: false
      TrueClass :enabled, default: true, null: false
      BigDecimal :amount, size: [10, 2], null: false
      Integer :months_period, default: 1, null: false
      Date :starts_on, null: false
      Date :ends_on
      String :note, size: 255, null: false
      column :tag_ids, 'integer[]'

      index :amount
      index :starts_on
      index :ends_on
    end
  end
end
