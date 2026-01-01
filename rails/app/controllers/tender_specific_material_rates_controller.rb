class TenderSpecificMaterialRatesController < ApplicationController
  before_action :set_tender
  before_action :set_tender_specific_material_rate, only: [:update, :destroy]

  # GET /tenders/:tender_id/tender_specific_material_rates
  def index
    @tender_specific_material_rates = @tender.tender_specific_material_rates
                                             .includes(:material_supply)
                                             .sort_by { |rate| rate.material_supply&.position || Float::INFINITY }
  end

  # POST /tenders/:tender_id/tender_specific_material_rates
  # Creates a new rate with default values and responds with Turbo Stream append
  def create
    @tender_specific_material_rate = @tender.tender_specific_material_rates.build(
      material_supply_id: nil,
      rate: nil,
      notes: nil
    )

    Rails.logger.info("🪲 DEBUG: Creating tender_specific_material_rate, id=#{@tender_specific_material_rate.id}, tender_id=#{@tender.id}")
    
    if @tender_specific_material_rate.save
      Rails.logger.info("🪲 DEBUG: Save successful, id=#{@tender_specific_material_rate.id}")
      respond_to do |format|
        Rails.logger.info("🪲 DEBUG: Responding with turbo_stream format")
        format.turbo_stream
        format.html { redirect_to tender_tender_specific_material_rates_path(@tender), notice: 'Material rate was successfully created.' }
      end
    else
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace(@tender_specific_material_rate, partial: "tender_specific_material_rates/tender_specific_material_rate", locals: { tender_specific_material_rate: @tender_specific_material_rate }) }
        format.html { render :index, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /tenders/:tender_id/tender_specific_material_rates/:id
  # Updates an existing rate and responds with Turbo Stream replace
  def update
    # Check if rate is being changed and if we need confirmation
    if rate_being_changed? && params[:confirm_cascade].nil?
      # Preview affected count and show confirmation dialog
      affected_count = count_affected_line_item_materials
      
      if affected_count > 0
        respond_to do |format|
          format.turbo_stream do
            render turbo_stream: turbo_stream.replace(
              @tender_specific_material_rate,
              partial: "tender_specific_material_rates/cascade_confirmation",
              locals: { 
                tender_specific_material_rate: @tender_specific_material_rate,
                affected_material_count: affected_count,
                new_rate: tender_specific_material_rate_params[:rate]
              }
            )
          end
          format.html { render :index }
        end
        return
      end
    end

    # Either no rate change, or cascade confirmed, or no affected materials - proceed with update
    if @tender_specific_material_rate.update(tender_specific_material_rate_params)
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            @tender_specific_material_rate,
            partial: "tender_specific_material_rates/tender_specific_material_rate",
            locals: { tender_specific_material_rate: @tender_specific_material_rate }
          )
        end
        format.html { redirect_to tender_tender_specific_material_rates_path(@tender), notice: 'Material rate was successfully updated.' }
      end
    else
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            @tender_specific_material_rate,
            partial: "tender_specific_material_rates/tender_specific_material_rate",
            locals: { tender_specific_material_rate: @tender_specific_material_rate }
          ), status: :unprocessable_entity
        end
        format.html { render :index, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /tenders/:tender_id/tender_specific_material_rates/:id
  # Deletes a rate and responds with Turbo Stream remove
  def destroy
    @tender_specific_material_rate.destroy

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.remove("tender_specific_material_rate_#{@tender_specific_material_rate.id}")
      end
      format.html { redirect_to tender_tender_specific_material_rates_path(@tender), notice: 'Material rate was successfully deleted.' }
    end
  end

  private

  def set_tender
    @tender = Tender.find(params[:tender_id])
  end

  def set_tender_specific_material_rate
    @tender_specific_material_rate = @tender.tender_specific_material_rates.find(params[:id])
  end

  def tender_specific_material_rate_params
    params.require(:tender_specific_material_rate).permit(:material_supply_id, :rate, :notes)
  end

  def rate_being_changed?
    tender_specific_material_rate_params[:rate].present? &&
      @tender_specific_material_rate.rate_changed?(to: tender_specific_material_rate_params[:rate].to_f)
  end

  def count_affected_line_item_materials
    return 0 unless @tender_specific_material_rate.material_supply_id.present?

    LineItemMaterial
      .where(material_supply_id: @tender_specific_material_rate.material_supply_id)
      .joins(:tender_line_item)
      .where(tender_line_items: { tender_id: @tender.id })
      .count
  end
end
