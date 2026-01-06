class TenderLineItemsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_tender, only: %i[ index new create edit update destroy reorder ]
  before_action :set_tender_line_item, only: %i[ show edit update destroy ]
  before_action :set_tender_from_line_item, only: %i[ show ], unless: -> { params[:tender_id].present? }

  # GET /tenders/:tender_id/tender_line_items or /tender_line_items
  def index
    @tender_line_items = @tender.tender_line_items.all
    respond_to do |format|
      format.html
      format.json { render json: @tender_line_items.map { |item| item.as_json.merge(line_item_rate_build_up_id: item.line_item_rate_build_up&.id) } }
    end
  end

  def reorder
    TenderLineItem.transaction do
      params[:ids].each_with_index do |id, index|
        @tender.tender_line_items.find(id).update_column(:position, index + 1)
      end
    end
    head :ok
  end

  # GET /tenders/:tender_id/tender_line_items/:id or /tender_line_items/:id
  def show
    respond_to do |format|
      format.html
      format.json { render json: @tender_line_item }
    end
  end

  # GET /tenders/:tender_id/tender_line_items/new or /tender_line_items/new
  def new
    @tender_line_item = @tender.tender_line_items.new
  end

  # GET /tenders/:tender_id/tender_line_items/:id/edit or /tender_line_items/:id/edit
  def edit
    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end

  # POST /tenders/:tender_id/tender_line_items or /tender_line_items
  def create
    # If params are provided, use them; otherwise create with defaults (instant creation)
    if params[:tender_line_item].present?
      @line_item = @tender.tender_line_items.new(tender_line_item_params)
    else
      # Instant creation with sensible defaults
      next_item_number = (@tender.tender_line_items.maximum(:item_number).to_i + 1).to_s
      @line_item = @tender.tender_line_items.new(
        item_number: next_item_number,
        item_description: "New Line Item",
        quantity: 0,
        rate: 0,
        unit_of_measure: "each",
        section_category_id: SectionCategory.find_by(name: 'blank')&.id || SectionCategory.first&.id
      )
    end

    respond_to do |format|
      if @line_item.save
        format.turbo_stream do
          render turbo_stream: turbo_stream.append(
            "line_items_container",
            partial: "tender_line_items/tender_line_item",
            locals: { tender_line_item: @line_item }
          )
        end
        format.html { redirect_to builder_tender_path(@tender), notice: 'Tender line item was successfully created.' }
        format.json { render json: @line_item, status: :created }
      else
        format.turbo_stream do
          flash.now[:error] = @line_item.errors.full_messages.to_sentence
          render turbo_stream: turbo_stream.update("flash", partial: "shared/flash"), status: :unprocessable_entity
        end
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @line_item.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /tenders/:tender_id/tender_line_items/:id or /tender_line_items/:id
  def update
    @line_item = @tender_line_item
    respond_to do |format|
      if @line_item.update(tender_line_item_params)
        format.turbo_stream { render :update }
        format.html { redirect_to builder_tender_path(@tender), notice: 'Tender line item was successfully updated.' }
        format.json { render json: @line_item }
      else
        format.turbo_stream do
          flash.now[:error] = @line_item.errors.full_messages.to_sentence
          render turbo_stream: [
            turbo_stream.update("flash", partial: "shared/flash"),
            turbo_stream.replace(@line_item, partial: "tender_line_items/tender_line_item", locals: { tender_line_item: @line_item })
          ], status: :unprocessable_entity
        end
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @line_item.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /tenders/:tender_id/tender_line_items/:id or /tender_line_items/:id
  def destroy
    @line_item = @tender_line_item
    @line_item.destroy
    respond_to do |format|
      format.turbo_stream { render :destroy }
      format.html { redirect_to builder_tender_path(@tender), notice: 'Tender line item was successfully deleted.' }
      format.json { head :no_content }
    end
  end

  private
    def set_tender
      @tender = Tender.find(params[:tender_id])
    end

    def set_tender_line_item
      @tender_line_item = if @tender
        @tender.tender_line_items.find(params[:id])
      else
        TenderLineItem.find(params[:id])
      end
    end

    def set_tender_from_line_item
      @tender = @tender_line_item.tender
    end

    def tender_line_item_params
      params.require(:tender_line_item).permit(
        :page_number, :item_number, :item_description, :section_category_id, 
        :unit_of_measure, :quantity, :rate, :notes, :is_heading,
        line_item_rate_build_up_attributes: [
          :id, :material_supply_rate, :fabrication_rate, :fabrication_included,
          :overheads_rate, :overheads_included, :shop_priming_rate,
          :shop_priming_included, :onsite_painting_rate, :onsite_painting_included,
          :delivery_rate, :delivery_included, :bolts_rate, :bolts_included, 
          :erection_rate, :erection_included, :crainage_rate, :crainage_included, 
          :cherry_picker_rate, :cherry_picker_included, :galvanizing_rate, 
          :galvanizing_included, :subtotal, :margin_amount, :total_before_rounding, 
          :rounded_rate, :_destroy
        ],
        line_item_material_breakdown_attributes: [
          :id, :_destroy,
          line_item_materials_attributes: [
            :id, :material_supply_id, :proportion_percentage, :_destroy
          ]
        ]
      )
    end
end
