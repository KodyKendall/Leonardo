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

    # Walks the user through putting the app on their phone's home screen.
    # GET /install
    def install
    end

    # Living reference for the app's shared visual language.
    # GET /brand
    def brand
    end
  end
