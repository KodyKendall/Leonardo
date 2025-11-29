class TendersController < ApplicationController
  before_action :set_tender, only: %i[ show edit update destroy update_inclusions_exclusions ]

  # GET /tenders or /tenders.json
  def index
    @tenders = Tender.all
    @tenders = @tenders.where(status: params[:status]) if params[:status].present?
  end

  # GET /tenders/1 or /tenders/1.json
  def show
  end

  # GET /tenders/1/builder
  def builder
    @tender = Tender.find(params[:id])
    @line_items = @tender.tender_line_items
                         .includes(:line_item_rate_build_up, 
                                   line_item_material_breakdown: :line_item_materials)
                         .order(:created_at)
  end

  # GET /tenders/new
  def new
    @tender = Tender.new
    @clients = Client.all
  end

  # GET /tenders/1/edit
  def edit
    @clients = Client.all
  end

  # POST /tenders or /tenders.json
  def create
    @tender = Tender.new(tender_params)

    respond_to do |format|
      if @tender.save
        format.html { redirect_to @tender, notice: "Tender was successfully created." }
        format.json { render :show, status: :created, location: @tender }
      else
        @clients = Client.all
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @tender.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /tenders/1 or /tenders/1.json
  def update
    respond_to do |format|
      if @tender.update(tender_params)
        format.html { redirect_to @tender, notice: "Tender was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @tender }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @tender.errors, status: :unprocessable_entity }
      end
    end
  end

  # POST /tenders/quick_create
  def quick_create
    @tender = Tender.new(status: 'Draft', tender_name: "New Tender")
    
    if @tender.save
      redirect_to @tender, notice: "Draft tender created. Complete the details below."
    else
      redirect_to tenders_path, alert: "Unable to create tender."
    end
  end

  # PATCH /tenders/1/update_inclusions_exclusions
  def update_inclusions_exclusions
    # Find or create the inclusions_exclusions record
    ie = @tender.tender_inclusions_exclusion || @tender.build_tender_inclusions_exclusion
    
    # Update with permitted parameters
    if ie.update(inclusions_exclusions_params)
      render json: { success: true, data: ie }, status: :ok
    else
      render json: { success: false, errors: ie.errors }, status: :unprocessable_entity
    end
  end

  # POST /tenders/1/mirror_boq_items
  def mirror_boq_items
    @tender = Tender.find(params[:id])
    
    # Get the first linked BOQ
    boq = @tender.boqs.first
    
    if !boq
      render json: { error: "No linked BOQ found" }, status: :unprocessable_entity
      return
    end
    
    # Mapping from BoqItem enum keys to TenderLineItem enum display names
    category_mapping = {
      "blank" => "Blank",
      "steel_sections" => "Steel Sections",
      "paintwork" => "Paintwork",
      "bolts" => "Bolts",
      "gutter_meter" => "Gutter Meter",
      "m16_mechanical_anchor" => "M16 Mechanical Anchor",
      "m16_chemical" => "M16 Chemical",
      "m20_chemical" => "M20 Chemical",
      "m24_chemical" => "M24 Chemical",
      "m16_hd_bolt" => "M16 HD Bolt",
      "m20_hd_bolt" => "M20 HD Bolt",
      "m24_hd_bolt" => "M24 HD Bolt",
      "m30_hd_bolt" => "M30 HD Bolt",
      "m36_hd_bolt" => "M36 HD Bolt",
      "m42_hd_bolt" => "M42 HD Bolt"
    }
    
    # Create Tender Line Items from BOQ items
    count = 0
    boq.boq_items.each do |boq_item|
      category_value = boq_item.section_category.present? ? category_mapping[boq_item.section_category] : nil
      
      @tender.tender_line_items.create(
        quantity: boq_item.quantity,
        rate: 0,
        item_number: boq_item.item_number,
        item_description: boq_item.item_description,
        unit_of_measure: boq_item.unit_of_measure,
        section_category: category_value,
        page_number: boq_item.page_number,
        notes: boq_item.notes
      )
      count += 1
    end
    
    render json: { success: true, count: count }, status: :created
  rescue => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  # DELETE /tenders/1 or /tenders/1.json
  def destroy
    @tender.destroy!

    respond_to do |format|
      format.html { redirect_to tenders_path, notice: "Tender was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_tender
      @tender = Tender.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def tender_params
      params.require(:tender).permit(:tender_name, :status, :client_id, :submission_deadline, :tender_value, :project_type, :notes, :awarded_project_id, :qob_file)
    end

    def inclusions_exclusions_params
      params.require(:tender_inclusions_exclusion).permit(
        :fabrication_included,
        :overheads_included,
        :primer_included,
        :final_paint_included,
        :delivery_included,
        :bolts_included,
        :erection_included,
        :crainage_included,
        :cherry_pickers_included,
        :steel_galvanized
      )
    end
end
