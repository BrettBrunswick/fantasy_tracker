class CreateTeams < ActiveRecord::Migration[8.0]
  def change
    create_table :teams do |t|
      t.references :season, null: false, foreign_key: true
      t.references :manager, null: false, foreign_key: true
      t.string :yahoo_team_key
      t.string :name

      t.timestamps
    end
    add_index :teams, :yahoo_team_key, unique: true
  end
end
