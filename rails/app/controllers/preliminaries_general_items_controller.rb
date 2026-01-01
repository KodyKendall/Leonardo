class PreliminariesGeneralItemsController < ApplicationController
  include ActionView::Helpers::NumberHelper
  include ActionView::RecordIdentifier
  
  before_action :set_tender
  before_action :set_preliminaries_general_item, only: %i[ show edit update destroy ]
  before_action :set_templates, only: %i[ index edit create update ]

  # GET /tenders/:tender_id/p_and_g
  def index
    @preliminaries_general_items = @tender.preliminaries_general_items.order(:sort_order, :created_at)
    @grouped_items = @preliminaries_general_items.group_by(&:category)
  end

  # GET /tenders/:tender_id/preliminaries_general_items/totals
  def totals
    render partial: "totals", locals: { tender: @tender }
  end

  # GET /tenders/:tender_id/p_and_g/1
  def show
    respond_to do |format|
      format.html { redirect_to tender_preliminaries_general_items_path(@tender) }
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(@preliminaries_general_item, 
                                partial: "preliminaries_general_items/preliminaries_general_item", 
                                locals: { preliminaries_general_item: @preliminaries_general_item, tender: @tender })
      end
    end
  end

  # GET /tenders/:tender_id/p_and_g/new
  def new
    @preliminaries_general_item = @tender.preliminaries_general_items.build
  end

  # GET /tenders/:tender_id/p_and_g/1/edit
  def edit
    respond_to do |format|
      format.html { render :edit }
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(@preliminaries_general_item, 
                                partial: "preliminaries_general_items/preliminaries_general_item", 
                                locals: { preliminaries_general_item: @preliminaries_general_item, editing: true, tender: @tender })
      end
    end
  end

  # POST /tenders/:tender_id/p_and_g
  def create
    # Use generic defaults if params are missing (for "Quick Add")
    create_params = preliminaries_general_item_params rescue { description: "New P&G Item", category: "fixed_based", quantity: 1, rate: 0 }
    @preliminaries_general_item = @tender.preliminaries_general_items.build(create_params)

    respond_to do |format|
      if @preliminaries_general_item.save
        format.json do
          render json: {
            id: @preliminaries_general_item.id,
            dom_id: dom_id(@preliminaries_general_item),
            description: @preliminaries_general_item.description,
            category: @preliminaries_general_item.category,
            category_display: @preliminaries_general_item.category.titleize,
            quantity: @preliminaries_general_item.quantity,
            quantity_display: number_with_precision(@preliminaries_general_item.quantity, precision: 3),
            rate: @preliminaries_general_item.rate,
            rate_display: number_to_currency(@preliminaries_general_item.rate),
            total_display: number_to_currency(@preliminaries_general_item.quantity * @preliminaries_general_item.rate)
          }
        end
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.append("pg_items_table_body", 
                                partial: "preliminaries_general_items/preliminaries_general_item", 
                                locals: { preliminaries_general_item: @preliminaries_general_item, editing: true, tender: @tender }),
            turbo_stream.replace("pg_totals", partial: "preliminaries_general_items/totals", locals: { tender: @tender })
          ]
        end
        format.html { redirect_to tender_preliminaries_general_items_path(@tender), notice: "Item added." }
      else
        format.html { render :new, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /tenders/:tender_id/p_and_g/1
  def update
    respond_to do |format|
      if @preliminaries_general_item.update(preliminaries_general_item_params)
        format.json do
          render json: {
            id: @preliminaries_general_item.id,
            description: @preliminaries_general_item.description,
            category_display: @preliminaries_general_item.category.titleize,
            quantity_display: number_with_precision(@preliminaries_general_item.quantity, precision: 3),
            rate_display: number_to_currency(@preliminaries_general_item.rate),
            total_display: number_to_currency(@preliminaries_general_item.quantity * @preliminaries_general_item.rate)
          }
        end
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace(@preliminaries_general_item, 
                                 partial: "preliminaries_general_items/preliminaries_general_item", 
                                 locals: { preliminaries_general_item: @preliminaries_general_item, tender: @tender }),
            turbo_stream.replace("pg_totals", partial: "preliminaries_general_items/totals", locals: { tender: @tender })
          ]
        end
        format.html { redirect_to tender_preliminaries_general_items_path(@tender), notice: "Item updated." }
      else
        format.turbo_stream { render turbo_stream: turbo_stream.replace(@preliminaries_general_item, partial: "preliminaries_general_items/preliminaries_general_item", locals: { preliminaries_general_item: @preliminaries_general_item, editing: true, tender: @tender }) }
        format.html { render :edit, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /tenders/:tender_id/p_and_g/1
  def destroy
    @preliminaries_general_item.destroy!

    respond_to do |format|
      format.json { render json: { success: true } }
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.remove(@preliminaries_general_item),
          turbo_stream.replace("pg_totals", partial: "preliminaries_general_items/totals", locals: { tender: @tender })
        ]
      end
      format.html { redirect_to tender_preliminaries_general_items_path(@tender), notice: "Item removed.", status: :see_other }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_tender
      @tender = Tender.find(params[:tender_id])
    end

    def set_preliminaries_general_item
      @preliminaries_general_item = @tender.preliminaries_general_items.find(params[:id])
    end

    def set_templates
      @templates = PreliminariesGeneralItemTemplate.order(:description)
    end

    # Only allow a list of trusted parameters through.
    def preliminaries_general_item_params
      params.require(:preliminaries_general_item).permit(:category, :description, :quantity, :rate, :sort_order, :is_crane, :is_access_equipment, :preliminaries_general_item_template_id)
    end
end
