# Module for handle simple create method
module Creatable
  extend ActiveSupport::Concern

  def create
    if item.save
      redirect_to send("#{ item_name }_url", item), :turbolinks => !request.format.html?
    else
      render :new
    end
  end

  private

  def item_name
    self.class.name.underscore.split('_').first.singularize
  end

  def item
    instance_variable_get("@#{ item_name }")
  end
end
