class CreateStandings < ActiveRecord::Migration[8.0]
  def change
    create_table :standings do |t|
      t.references :season, null: false, foreign_key: true
      t.references :team, null: false, foreign_key: true
      t.integer :rank
      t.integer :wins, default: 0
      t.integer :losses, default: 0
      t.integer :ties, default: 0
      t.decimal :points_for, precision: 10, scale: 2, default: 0
      t.decimal :points_against, precision: 10, scale: 2, default: 0

      t.timestamps
    end

    add_index :standings, [:season_id, :team_id], unique: true
  end
end
