if Rails.env.development?
  ActionMailer::Base.smtp_settings = {
    :address => 'smtp.gmail.com',
    :port => 587,
    :domain => 'gmail.com',
    :authentication => :plain,
    :user_name => Settings.mailer.user_name,
    :password => Settings.mailer.password,
    :enable_starttls_auto => true
  }
end
