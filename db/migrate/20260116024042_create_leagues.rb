class CreateLeagues < ActiveRecord::Migration[8.0]
  def change
    create_table :leagues do |t|
      t.string :name
      t.string :yahoo_league_key

      t.timestamps
    end
  end
end
