Sequel.migration do
  change do
    alter_table :balances do
      add_column :target_amount, BigDecimal, size: [11, 2]
    end
  end
end
