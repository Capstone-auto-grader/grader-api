class CreateContainers < ActiveRecord::Migration[5.2]
  def change
    create_table :containers do |t|
      t.string :config_uri
      t.string :uid
      t.string :name

      t.timestamps
    end
  end
end
