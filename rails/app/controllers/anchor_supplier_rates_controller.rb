class AnchorSupplierRatesController < ApplicationController
  before_action :set_anchor_supplier_rate, only: %i[ update destroy ]

  # POST /anchor_supplier_rates.json
  def create
    @anchor_supplier_rate = AnchorSupplierRate.new(anchor_supplier_rate_params)

    if @anchor_supplier_rate.save
      render json: { 
        success: true, 
        id: @anchor_supplier_rate.id,
        anchor_rate_material_cost: @anchor_supplier_rate.anchor_rate.material_cost
      }
    else
      render json: { success: false, error: @anchor_supplier_rate.errors.full_messages.join(", ") }, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /anchor_supplier_rates/1.json
  def update
    if @anchor_supplier_rate.update(anchor_supplier_rate_params)
      render json: { 
        success: true, 
        id: @anchor_supplier_rate.id,
        anchor_rate_material_cost: @anchor_supplier_rate.anchor_rate.material_cost
      }
    else
      render json: { success: false, error: @anchor_supplier_rate.errors.full_messages.join(", ") }, status: :unprocessable_entity
    end
  end

  # DELETE /anchor_supplier_rates/1.json
  def destroy
    anchor_rate = @anchor_supplier_rate.anchor_rate
    @anchor_supplier_rate.destroy!
    render json: { 
      success: true, 
      anchor_rate_material_cost: anchor_rate.reload.material_cost 
    }
  end

  private

  def set_anchor_supplier_rate
    @anchor_supplier_rate = AnchorSupplierRate.find(params[:id])
  end

  def anchor_supplier_rate_params
    params.require(:anchor_supplier_rate).permit(:anchor_rate_id, :supplier_id, :rate, :is_winner)
  end
end
