Sequel.migration do
  change do
    alter_table :tags do
      add_column :icon, String, size: 40
    end
  end
end
