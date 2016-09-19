# Authentication utilities
module AuthenticationUtilities
  class << self
    def params_from_omniauth(params)
      params_credentials = params[:credentials]

      {
        :meta => params.to_json,
        :token => params_credentials.try(:[], :token),
        :secret => params_credentials.try(:[], :secret),
        :gitlab_private_token => params['extra'].try(:[], 'raw_info').try(:[], 'private_token')
      }
    end
  end
end
