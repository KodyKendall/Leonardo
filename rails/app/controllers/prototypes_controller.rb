class PrototypesController < ApplicationController
  def show
    page = params[:page]
    if lookup_context.exists?(page, ["prototypes"], false)
      render "prototypes/#{page}"
    else
      render plain: "Prototype not found", status: :not_found
    end
  end
end
