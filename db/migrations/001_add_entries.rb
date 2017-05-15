Sequel.migration do
  change do
    create_table :entries do
      primary_key :id

      BigDecimal :amount, size: [10, 2], null: false
      Date :date, null: false
      Date :accounted_on
      String :note, size: 255

      index :amount
      index :date
      index :accounted_on
    end
  end
end
