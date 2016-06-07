class CreateAuthentications < ActiveRecord::Migration
  def change
    create_table :authentications do |t|
      t.string :provider, :null => false

      t.string :uid, :null => false

      t.string :token

      t.belongs_to :user, :index => true

      t.string :secret

      t.jsonb :meta, :default => {}

      t.timestamps :null => false
    end

    add_index :authentications, [:provider, :uid]
  end
end
