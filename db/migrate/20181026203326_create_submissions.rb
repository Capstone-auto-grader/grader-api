class CreateSubmissions < ActiveRecord::Migration[5.2]
  def change
    create_table :submissions do |t|
      t.string :proj_id
      t.string :container_id
      t.text :result

      t.timestamps
    end
  end
end
