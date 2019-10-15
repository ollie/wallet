Sequel.migration do
  change do
    create_table :balances do
      primary_key :id

      BigDecimal :amount, size: [11, 2], null: false
      String :year_month, size: 7, null: false
      String :note, size: 255

      index :year_month, unique: true
    end
  end
end
