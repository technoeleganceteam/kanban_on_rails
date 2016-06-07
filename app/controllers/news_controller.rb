class NewsController < ApplicationController
  include HighVoltage::StaticPage

  before_action :assign_content_path

  def index
    @news = Kaminari.paginate_array(HighVoltage.page_ids.sort).page(params[:page])
  end

  private

  def assign_content_path
    HighVoltage.content_path = 'news/'
  end
end
