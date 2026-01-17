class CreateHeadToHeadRecords < ActiveRecord::Migration[8.0]
  def change
    create_table :head_to_head_records do |t|
      t.references :manager, null: false, foreign_key: true
      t.references :opponent_manager, null: false, foreign_key: { to_table: :managers }
      t.references :league, null: false, foreign_key: true
      t.integer :regular_season_wins, default: 0
      t.integer :regular_season_losses, default: 0
      t.integer :regular_season_ties, default: 0
      t.integer :playoff_wins, default: 0
      t.integer :playoff_losses, default: 0

      t.timestamps
    end

    add_index :head_to_head_records, [:manager_id, :opponent_manager_id, :league_id], unique: true, name: 'idx_h2h_manager_opponent_league'
  end
end
