class CreateJobRuns < ActiveRecord::Migration[8.1]
  def change
    create_table :job_runs do |t|
      t.string :job_class
      t.string :account_id
      t.jsonb :payload
      t.datetime :ran_at

      t.timestamps
    end
  end
end
