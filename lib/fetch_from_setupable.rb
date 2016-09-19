# Provide initialize method for fetch from services.
module FetchFromSetupable
  extend ActiveSupport::Concern

  def setup(params = {})
    @project = params[:project]

    @client = params[:client]
  end
end
