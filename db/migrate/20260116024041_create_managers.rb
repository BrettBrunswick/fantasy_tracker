class CreateManagers < ActiveRecord::Migration[8.0]
  def change
    create_table :managers do |t|
      t.string :name
      t.string :email
      t.string :yahoo_guid

      t.timestamps
    end
    add_index :managers, :yahoo_guid, unique: true
  end
end
