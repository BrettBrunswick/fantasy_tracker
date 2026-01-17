class CreateUserJobs < ActiveRecord::Migration[8.0]
  def change
    create_table :user_jobs do |t|
      t.references :user, null: false, foreign_key: true
      t.string :job_id
      t.string :job_type
      t.string :status
      t.text :message
      t.datetime :started_at
      t.datetime :completed_at

      t.timestamps
    end

    add_index :user_jobs, :job_id, unique: true
    add_index :user_jobs, [:user_id, :status]
  end
end
