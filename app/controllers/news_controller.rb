# Controller for handle news
class NewsController < ApplicationController
  include HighVoltage::StaticPage
  include ContentPathable

  def index
    @news = Kaminari.paginate_array(HighVoltage.page_ids.sort).page(params[:page])
  end
end
