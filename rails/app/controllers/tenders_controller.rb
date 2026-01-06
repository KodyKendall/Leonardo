class TendersController < ApplicationController
  before_action :set_tender, only: %i[ show edit update destroy update_inclusions_exclusions tender_inclusions_exclusions sync_all_inclusions_exclusions report ]

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
                         .ordered
  end

  # GET /tenders/1/report
  # Print-ready report view for PDF generation via Grover
  def report
    @line_items = @tender.tender_line_items
                         .includes(:line_item_rate_build_up)
                         .ordered
    @p_and_g_items = @tender.preliminaries_general_items
    @shop_drawings_total = @tender.project_rate_buildup&.shop_drawings_total || 0

    respond_to do |format|
      format.html { render layout: 'print' }
      format.pdf do
        html = render_to_string(template: 'tenders/report', layout: 'print', formats: [:html])
        grover = Grover.new(html,
          format: 'Letter',
          margin: { top: '0', bottom: '0', left: '0', right: '0' },
          emulate_media: 'print',
          display_header_footer: false,
          prefer_css_page_size: true,
          wait_until: 'networkidle0',
          display_url: request.base_url,
          print_background: true
        )
        pdf = grover.to_pdf
        send_data pdf,
                  filename: "tender_#{@tender.e_number}.pdf",
                  type: 'application/pdf',
                  disposition: 'attachment'
      end
    end
  end

  # GET /tenders/1/tender_inclusions_exclusions
  def tender_inclusions_exclusions
    @tender = Tender.find(params[:id])
    @tender_inclusions_exclusion = @tender.tender_inclusions_exclusion || @tender.build_tender_inclusions_exclusion
  end

  # GET /tenders/1/material_autofill
  # Returns autofill data: tender-specific rate + material waste percentage
  def material_autofill
    @tender = Tender.find(params[:id])
    material_supply_id = params[:material_supply_id]

    unless material_supply_id.present?
      render json: { error: "material_supply_id is required" }, status: :bad_request
      return
    end

    # Fetch tender-specific rate for this material
    tender_rate = TenderSpecificMaterialRate.find_by(
      tender_id: @tender.id,
      material_supply_id: material_supply_id
    )

    # Fetch material's default waste percentage
    material = MaterialSupply.find_by(id: material_supply_id)

    render json: {
      rate: tender_rate&.rate,
      waste_percentage: material&.waste_percentage
    }, status: :ok
  rescue => e
    render json: { error: e.message }, status: :unprocessable_entity
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
        @clients = Client.all
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @tender.errors, status: :unprocessable_entity }
      end
    end
  end

  # POST /tenders/quick_create
  def quick_create
    @tender = Tender.new(status: 'Draft', tender_name: 'Temp')
    @tender.save  # This triggers generate_e_number
    
    # Now set tender_name to the generated e_number
    @tender.update(tender_name: @tender.e_number)
    
    if @tender.persisted?
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

  # POST /tenders/1/sync_all_inclusions_exclusions
  def sync_all_inclusions_exclusions
    ie = @tender.tender_inclusions_exclusion || @tender.build_tender_inclusions_exclusion
    
    if ie.persisted? || ie.save
      ie.sync_all_to_line_items!
      redirect_to tender_inclusions_exclusions_tender_path(@tender), notice: "Successfully synced all inclusions to line items."
    else
      redirect_to tender_inclusions_exclusions_tender_path(@tender), alert: "Unable to sync inclusions: #{ie.errors.full_messages.join(', ')}"
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
      category_name = boq_item.section_category.present? ? category_mapping[boq_item.section_category] : nil
      section_category = SectionCategory.find_by(display_name: category_name) if category_name
      
      @tender.tender_line_items.create(
        quantity: boq_item.quantity,
        rate: 0,
        item_number: boq_item.item_number,
        item_description: boq_item.item_description,
        unit_of_measure: boq_item.unit_of_measure,
        section_category: section_category,
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
      params.require(:tender).permit(:tender_name, :status, :client_id, :contact_id, :submission_deadline, :tender_value, :project_type, :notes, :awarded_project_id, :qob_file)
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
