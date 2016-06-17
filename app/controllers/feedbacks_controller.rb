class FeedbacksController < ApplicationController
  load_resource

  before_action :check_recaptcha, :only => [:create]

  def new
    @feedback = Feedback.new
  end

  def create
    if @feedback.save
      render
    else
      render :new
    end
  end

  private

  def feedback_params
    params.require(:feedback).permit(:name, :email, :content)
  end

  def check_recaptcha
    return if user_signed_in?

    (render(:new) && return) unless verify_recaptcha(:model => @feedback)
  end
end
