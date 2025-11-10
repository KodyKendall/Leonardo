class BoqItemsController < ApplicationController
  include LlamaBotRails::ControllerExtensions
  include LlamaBotRails::AgentAuth
  skip_before_action :verify_authenticity_token, only: [:create, :update, :destroy]
  before_action :authenticate_user!
  before_action :set_boq_item, only: [:show, :update, :destroy]

  # Whitelist actions for LangGraph agent access
  llama_bot_allow :index, :show, :create, :update, :destroy

  def index
    @boq_items = BoqItem.all
    respond_to do |format|
      format.json { render json: @boq_items }
    end
  end

  def show
    respond_to do |format|
      format.json { render json: @boq_item }
    end
  end

  def create
    @boq_item = BoqItem.new(boq_item_params)

    respond_to do |format|
      if @boq_item.save
        format.json { render json: @boq_item, status: :created }
      else
        format.json { render json: @boq_item.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @boq_item.update(boq_item_params)
        format.json { render json: @boq_item }
      else
        format.json { render json: @boq_item.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @boq_item.destroy
    respond_to do |format|
      format.json { head :no_content }
    end
  end

  private

  def set_boq_item
    @boq_item = BoqItem.find(params[:id])
  end

  def boq_item_params
    params.require(:boq_item).permit(:boq_id, :item_number, :item_description, :unit_of_measure, :quantity, :section_category, :sequence_order, :notes)
  end
end
