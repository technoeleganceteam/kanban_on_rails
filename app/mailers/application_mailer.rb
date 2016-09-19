# Common application mailer
class ApplicationMailer < ActionMailer::Base
  default :from => Settings.mailer.from_name

  layout 'mailer'
end
