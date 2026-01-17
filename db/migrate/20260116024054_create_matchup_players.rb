class CreateMatchupPlayers < ActiveRecord::Migration[8.0]
  def change
    create_table :matchup_players do |t|
      t.references :matchup, null: false, foreign_key: true
      t.references :team, null: false, foreign_key: true
      t.string :yahoo_player_key
      t.string :player_name
      t.string :position
      t.decimal :points, precision: 10, scale: 2

      t.timestamps
    end

    add_index :matchup_players, [:matchup_id, :team_id, :yahoo_player_key], unique: true, name: 'idx_matchup_players_unique'
  end
end
