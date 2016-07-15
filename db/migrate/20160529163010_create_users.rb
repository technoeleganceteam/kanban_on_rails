class CreateUsers < ActiveRecord::Migration
  def change
    create_table(:users) do |t|
      t.string :email, :null => false, :default => ''

      t.string :encrypted_password, :null => false, :default => ''

      t.string :reset_password_token

      t.datetime :reset_password_sent_at

      t.datetime :remember_created_at

      t.integer :sign_in_count, :default => 0, :null => false

      t.datetime :current_sign_in_at

      t.datetime :last_sign_in_at

      t.inet :current_sign_in_ip

      t.inet :last_sign_in_ip

      t.string :confirmation_token

      t.datetime :confirmed_at

      t.datetime :confirmation_sent_at

      t.string :unconfirmed_email

      t.string :locale, :null => false, :default => 'en'

      t.string :name, :null => false

      t.string :avatar_url

      t.string :time_zone

      t.jsonb :meta, :default => {}

      t.timestamps :null => false
    end

    add_index :users, :email, :unique => true

    add_index :users, :reset_password_token, :unique => true

    add_index :users, :confirmation_token, :unique => true
  end
end
