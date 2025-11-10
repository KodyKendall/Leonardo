class BoqItemsController < ApplicationController
  include LlamaBotRails::ControllerExtensions
  include LlamaBotRails::AgentAuth
  skip_before_action :verify_authenticity_token, only: [:create, :update, :destroy]
  before_action :authenticate_user!
  before_action :set_boq_item, only: [:show, :update, :destroy]

  # Whitelist actions for LangGraph agent access
  llama_bot_allow :index, :show, :create, :update, :destroy

  def index
    # Scope to BOQ items belonging to current user's BOQs
    @boq_items = BoqItem.joins(:boq).where(boqs: { uploaded_by_id: current_user.id })
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
    # Verify the BOQ belongs to current user before creating item
    boq = Boq.find_by(id: boq_item_params[:boq_id], uploaded_by_id: current_user.id)
    
    unless boq
      return respond_to do |format|
        format.json { render json: { error: "BOQ not found or unauthorized" }, status: :forbidden }
      end
    end

    @boq_item = boq.boq_items.new(boq_item_params)

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
    # Scope to BOQ items belonging to current user's BOQs
    @boq_item = BoqItem.joins(:boq).find_by(id: params[:id], boqs: { uploaded_by_id: current_user.id })
    
    unless @boq_item
      respond_to do |format|
        format.json { render json: { error: "BOQ item not found or unauthorized" }, status: :not_found }
      end
    end
  end

  def boq_item_params
    params.require(:boq_item).permit(:boq_id, :item_number, :item_description, :unit_of_measure, :quantity, :section_category, :sequence_order, :notes)
  end
end
