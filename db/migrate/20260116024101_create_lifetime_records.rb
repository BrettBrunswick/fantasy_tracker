class CreateLifetimeRecords < ActiveRecord::Migration[8.0]
  def change
    create_table :lifetime_records do |t|
      t.references :manager, null: false, foreign_key: true
      t.references :league, null: false, foreign_key: true
      t.integer :regular_season_wins, default: 0
      t.integer :regular_season_losses, default: 0
      t.integer :regular_season_ties, default: 0
      t.integer :playoff_wins, default: 0
      t.integer :playoff_losses, default: 0
      t.integer :championships_won, default: 0
      t.integer :championships_lost, default: 0
      t.decimal :total_points_for, precision: 10, scale: 2, default: 0
      t.decimal :total_points_against, precision: 10, scale: 2, default: 0

      t.timestamps
    end

    add_index :lifetime_records, [:manager_id, :league_id], unique: true
  end
end
