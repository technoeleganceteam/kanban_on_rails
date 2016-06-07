Warden::Manager.after_set_user do |user, auth, opts|
  scope = opts[:scope]

  auth.cookies.signed["#{ scope }.id"] = user.id

  auth.cookies[:signed_in] = 1
end

Warden::Manager.before_logout do |user, auth, opts|
  scope = opts[:scope]

  auth.cookies.signed["#{ scope }.id"] = nil

  ActionCable.server.disconnect(:current_user => user)

  auth.cookies.delete :signed_in
end
