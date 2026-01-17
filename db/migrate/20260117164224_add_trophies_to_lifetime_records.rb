class AddTrophiesToLifetimeRecords < ActiveRecord::Migration[8.0]
  def change
    add_column :lifetime_records, :first_place_finishes, :integer, default: 0
    add_column :lifetime_records, :second_place_finishes, :integer, default: 0
    add_column :lifetime_records, :third_place_finishes, :integer, default: 0
  end
end
