class TenderLineItemsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_tender, only: %i[ index show create edit update destroy ]
  before_action :set_tender_line_item, only: %i[ show edit update destroy ]

  # GET /tenders/:tender_id/tender_line_items or /tender_line_items
  def index
    @tender_line_items = @tender.tender_line_items.all
    respond_to do |format|
      format.html
      format.json { render json: @tender_line_items.map { |item| item.as_json.merge(line_item_rate_build_up_id: item.line_item_rate_build_up&.id) } }
    end
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
  end

  # POST /tenders/:tender_id/tender_line_items or /tender_line_items
  def create
    @tender_line_item = @tender.tender_line_items.new(tender_line_item_params)

    respond_to do |format|
      if @tender_line_item.save
        format.html { redirect_to tender_path(@tender), notice: 'Tender line item was successfully created.' }
        format.json { render json: @tender_line_item, status: :created }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @tender_line_item.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /tenders/:tender_id/tender_line_items/:id or /tender_line_items/:id
  def update
    respond_to do |format|
      if @tender_line_item.update(tender_line_item_params)
        format.html { redirect_to tender_path(@tender), notice: 'Tender line item was successfully updated.' }
        format.json { render json: @tender_line_item }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @tender_line_item.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /tenders/:tender_id/tender_line_items/:id or /tender_line_items/:id
  def destroy
    @tender_line_item.destroy
    respond_to do |format|
      format.html { redirect_to tender_path(@tender), notice: 'Tender line item was successfully deleted.' }
      format.json { head :no_content }
    end
  end

  private
    def set_tender
      @tender = Tender.find(params[:tender_id])
    end

    def set_tender_line_item
      @tender_line_item = @tender.tender_line_items.find(params[:id])
    end

    def tender_line_item_params
      params.require(:tender_line_item).permit(:page_number, :item_number, :item_description, :section_category, :unit_of_measure, :quantity, :rate)
    end
end
