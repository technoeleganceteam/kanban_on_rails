class CreateFeedbacks < ActiveRecord::Migration
  def change
    create_table :feedbacks do |t|
      t.string :name, :null => false

      t.string :email, :null => false

      t.text :content, :null => false

      t.timestamps :null => false
    end
  end
end
