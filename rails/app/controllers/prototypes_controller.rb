class PrototypesController < ApplicationController
  layout "prototypes"

  def show
    page = params[:page]
    if lookup_context.exists?(page, ["prototypes"], false)
      @view_path = "app/views/prototypes/#{page}.html.erb" # it's necessary to overwrite this otherwise Leonardo gets super confused and tries to Read /app/views/prototypes/show.html.erb over and over and over again. (This @view_path gets passed into Leonardo's system prompt)
      render "prototypes/#{page}"
    else
      render plain: "Prototype not found", status: :not_found
    end
  end
end
