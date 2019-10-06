class ChangeImageNameToContainerId < ActiveRecord::Migration[5.2]
  def change
    remove_column :submissions, :image_name
    add_column :submissions, :image_id, :integer
  end
end
