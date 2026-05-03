class PublicController < ApplicationController
    skip_before_action :authenticate_user!, raise: false
  
    # Root page of our application.
    # GET /
    def home
    end

    # Chat page of our application.
    # GET /chat
    def chat
    end
  end
