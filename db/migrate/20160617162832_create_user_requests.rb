class CreateUserRequests < ActiveRecord::Migration
  def change
    create_table :user_requests do |t|
      t.belongs_to :user, :index => true

      t.text :content

      t.integer :likes_count, :default => 0

      t.timestamps :null => false
    end
  end
end
