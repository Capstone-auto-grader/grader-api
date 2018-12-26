class AddContainerNameToSubmission < ActiveRecord::Migration[5.2]
  def change
    add_column :submissions, :image_name, :string
  end
end
