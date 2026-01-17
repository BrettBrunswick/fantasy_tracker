class CreateSeasons < ActiveRecord::Migration[8.0]
  def change
    create_table :seasons do |t|
      t.references :league, null: false, foreign_key: true
      t.integer :year
      t.string :yahoo_league_key
      t.string :yahoo_game_id

      t.timestamps
    end
  end
end
