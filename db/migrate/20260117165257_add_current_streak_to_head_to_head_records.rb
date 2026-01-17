class AddCurrentStreakToHeadToHeadRecords < ActiveRecord::Migration[8.0]
  def change
    add_column :head_to_head_records, :current_streak, :string
  end
end
