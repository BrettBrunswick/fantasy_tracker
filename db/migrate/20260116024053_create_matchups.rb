class CreateMatchups < ActiveRecord::Migration[8.0]
  def change
    create_table :matchups do |t|
      t.references :season, null: false, foreign_key: true
      t.integer :week
      t.string :yahoo_matchup_key
      t.references :team_1, null: false, foreign_key: { to_table: :teams }
      t.references :team_2, null: false, foreign_key: { to_table: :teams }
      t.decimal :team_1_score, precision: 10, scale: 2
      t.decimal :team_2_score, precision: 10, scale: 2
      t.references :winner, null: true, foreign_key: { to_table: :teams }
      t.integer :matchup_type, default: 0

      t.timestamps
    end

    add_index :matchups, [:season_id, :week]
  end
end
