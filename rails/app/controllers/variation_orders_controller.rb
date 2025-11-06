class VariationOrdersController < ApplicationController
  before_action :set_variation_order, only: %i[ show edit update destroy ]

  # GET /variation_orders or /variation_orders.json
  def index
    @variation_orders = VariationOrder.all
  end

  # GET /variation_orders/1 or /variation_orders/1.json
  def show
  end

  # GET /variation_orders/new
  def new
    @variation_order = VariationOrder.new
  end

  # GET /variation_orders/1/edit
  def edit
  end

  # POST /variation_orders or /variation_orders.json
  def create
    @variation_order = VariationOrder.new(variation_order_params)

    respond_to do |format|
      if @variation_order.save
        format.html { redirect_to @variation_order, notice: "Variation order was successfully created." }
        format.json { render :show, status: :created, location: @variation_order }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @variation_order.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /variation_orders/1 or /variation_orders/1.json
  def update
    respond_to do |format|
      if @variation_order.update(variation_order_params)
        format.html { redirect_to @variation_order, notice: "Variation order was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @variation_order }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @variation_order.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /variation_orders/1 or /variation_orders/1.json
  def destroy
    @variation_order.destroy!

    respond_to do |format|
      format.html { redirect_to variation_orders_path, notice: "Variation order was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_variation_order
      @variation_order = VariationOrder.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def variation_order_params
      params.require(:variation_order).permit(:vo_number, :project_id, :vo_status, :vo_amount, :description, :created_by_id, :approved_by_id, :approver_notes, :approved_at)
    end
end
