module Rack
  class Attack
    throttle('logins/ip', :limit => 10, :period => 300.seconds) do |req|
      req.ip if req.path == '/users/sign_in' && req.post? && Rails.env.production?
    end

    throttle('feedbacks/ip', :limit => 5, :period => 300.seconds) do |req|
      req.ip if req.path == '/feedbacks' && req.post? && Rails.env.production?
    end

    throttle('logins/email', :limit => 10, :period => 300.seconds) do |req|
      req.params['user'].try(:[], 'email') if req.path == '/users/sign_in' && req.post? && Rails.env.production?
    end

    throttle('req/ip', :limit => 300, :period => 1.minute) do |req|
      req.ip if Rails.env.production?
    end

    throttle('confirmations/ip', :limit => 5, :period => 300.seconds) do |req|
      req.ip if req.path == '/users/confirmation' && req.post? && Rails.env.production?
    end

    throttle('passwords/email', :limit => 5, :period => 1.minute) do |req|
      req.params['user'].try(:[], 'email') if req.path == '/users/password' && req.post? && Rails.env.production?
    end
  end
end
