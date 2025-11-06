class ClaimLineItemsController < ApplicationController
  before_action :set_claim_line_item, only: %i[ show edit update destroy ]

  # GET /claim_line_items or /claim_line_items.json
  def index
    @claim_line_items = ClaimLineItem.all
  end

  # GET /claim_line_items/1 or /claim_line_items/1.json
  def show
  end

  # GET /claim_line_items/new
  def new
    @claim_line_item = ClaimLineItem.new
  end

  # GET /claim_line_items/1/edit
  def edit
  end

  # POST /claim_line_items or /claim_line_items.json
  def create
    @claim_line_item = ClaimLineItem.new(claim_line_item_params)

    respond_to do |format|
      if @claim_line_item.save
        format.html { redirect_to @claim_line_item, notice: "Claim line item was successfully created." }
        format.json { render :show, status: :created, location: @claim_line_item }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @claim_line_item.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /claim_line_items/1 or /claim_line_items/1.json
  def update
    respond_to do |format|
      if @claim_line_item.update(claim_line_item_params)
        format.html { redirect_to @claim_line_item, notice: "Claim line item was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @claim_line_item }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @claim_line_item.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /claim_line_items/1 or /claim_line_items/1.json
  def destroy
    @claim_line_item.destroy!

    respond_to do |format|
      format.html { redirect_to claim_line_items_path, notice: "Claim line item was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_claim_line_item
      @claim_line_item = ClaimLineItem.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def claim_line_item_params
      params.require(:claim_line_item).permit(:claim_id, :line_item_description, :tender_rate, :claimed_quantity, :claimed_amount, :cumulative_quantity, :is_new_item, :price_escalation)
    end
end
