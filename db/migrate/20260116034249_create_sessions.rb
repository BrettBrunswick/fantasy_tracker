class CreateSessions < ActiveRecord::Migration[8.0]
  def change
    create_table :sessions do |t|
      t.string :session_id
      t.text :data

      t.timestamps
    end
    add_index :sessions, :session_id, unique: true
  end
end
