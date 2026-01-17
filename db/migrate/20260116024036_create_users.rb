class CreateUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :users do |t|
      t.string :email
      t.string :yahoo_uid
      t.text :access_token
      t.text :refresh_token
      t.datetime :token_expires_at

      t.timestamps
    end
    add_index :users, :email, unique: true
    add_index :users, :yahoo_uid, unique: true
  end
end
