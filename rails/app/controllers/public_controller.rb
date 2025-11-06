class PublicController < ApplicationController
    skip_before_action :authenticate_user!
  
    # Root page of our application.
    # GET /
    def home
      redirect_to dashboard_path if user_signed_in?
    end

    # Chat page of our application.
    # GET /chat
    def chat
    end
  end
