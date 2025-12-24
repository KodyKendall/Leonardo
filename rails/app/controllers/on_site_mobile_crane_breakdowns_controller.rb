class OnSiteMobileCraneBreakdownsController < ApplicationController
  before_action :set_on_site_mobile_crane_breakdown, only: %i[ show edit update destroy builder populate_crane_selections ]

  # GET /on_site_mobile_crane_breakdowns or /on_site_mobile_crane_breakdowns.json
  def index
    @on_site_mobile_crane_breakdowns = OnSiteMobileCraneBreakdown.all
  end

  # GET /on_site_mobile_crane_breakdowns/1 or /on_site_mobile_crane_breakdowns/1.json
  def show
  end

  # GET /on_site_mobile_crane_breakdowns/1/builder
  def builder
    @crane_complements = CraneComplement.all
    @crane_rates = CraneRate.all
  end

  # POST /on_site_mobile_crane_breakdowns/1/populate_crane_selections
  def populate_crane_selections
    breakdown = @on_site_mobile_crane_breakdown
    tender = breakdown.tender
    
    # Find the matching crane complement
    matching_complement = CraneComplement.find_by("? >= area_min_sqm AND ? <= area_max_sqm",
                                                   breakdown.erection_rate_sqm_per_day,
                                                   breakdown.erection_rate_sqm_per_day)
    
    unless matching_complement
      flash.alert = "No matching crane complement found for this area."
      return render turbo_stream: turbo_stream.replace("flash", partial: "shared/flash")
    end

    # Parse the crane_recommendation text
    # Expected format: "2 × 10t + 1 × 25t + 2 × 35t"
    recommendation = matching_complement.crane_recommendation
    pattern = /(\d+)\s*[×x]\s*(\d+)t/i
    matches = recommendation.scan(pattern)

    if matches.empty?
      flash.alert = "Could not parse crane recommendation."
      return render turbo_stream: turbo_stream.replace("flash", partial: "shared/flash")
    end

    missing_rates = []
    created_count = 0

    # CREATE RECOMMENDED CRANES (existing behavior)
    matches.each do |quantity_str, size_str|
      quantity = quantity_str.to_i
      size = "#{size_str}t"

      # Find matching crane rate (most recent if duplicates exist)
      crane_rate = CraneRate.where(size: size, ownership_type: breakdown.ownership_type, is_active: true).order(effective_from: :desc).first

      if crane_rate.nil?
        missing_rates << size
        next
      end

      # Create the tender crane selection
      selection = TenderCraneSelection.new(
        tender_id: tender.id,
        crane_rate_id: crane_rate.id,
        quantity: quantity,
        purpose: "main",
        on_site_mobile_crane_breakdown_id: breakdown.id
      )

      if selection.save
        created_count += 1
      end
    end

    # CREATE SPLICING CRANE (if required and size is populated)
    if breakdown.splicing_crane_required? && breakdown.splicing_crane_size.present?
      splicing_size = breakdown.splicing_crane_size
      # Use validated format directly (validation ensures it's in format: \d+t)
      # No normalization needed since model validation enforces lowercase 't'

      splicing_rate = CraneRate.where(size: splicing_size, ownership_type: breakdown.ownership_type, is_active: true).order(effective_from: :desc).first

      if splicing_rate.nil?
        missing_rates << "Splicing (#{splicing_size})"
      else
        splicing_selection = TenderCraneSelection.new(
          tender_id: tender.id,
          crane_rate_id: splicing_rate.id,
          quantity: 1,
          purpose: "splicing",
          on_site_mobile_crane_breakdown_id: breakdown.id
        )

        if splicing_selection.save
          created_count += 1
        end
      end
    end

    # CREATE MISC CRANE (if required and size is populated)
    if breakdown.misc_crane_required? && breakdown.misc_crane_size.present?
      misc_size = breakdown.misc_crane_size
      # Use validated format directly (validation ensures it's in format: \d+t)
      # No normalization needed since model validation enforces lowercase 't'

      misc_rate = CraneRate.where(size: misc_size, ownership_type: breakdown.ownership_type, is_active: true).order(effective_from: :desc).first

      if misc_rate.nil?
        missing_rates << "Misc (#{misc_size})"
      else
        misc_selection = TenderCraneSelection.new(
          tender_id: tender.id,
          crane_rate_id: misc_rate.id,
          quantity: 1,
          purpose: "misc",
          on_site_mobile_crane_breakdown_id: breakdown.id
        )

        if misc_selection.save
          created_count += 1
        end
      end
    end

    # Build flash message
    flash_message = "Added #{created_count} crane selection(s)."
    if missing_rates.any?
      flash_message += " Warning: No active rates found for: #{missing_rates.join(', ')}"
      flash.notice = flash_message
    else
      flash.notice = flash_message
    end

    respond_to do |format|
      format.turbo_stream do
        updates = [
          turbo_stream.replace("flash", partial: "shared/flash"),
          turbo_stream.replace("tender_crane_selections", 
            partial: "tender_crane_selections/index",
            locals: { 
              tender_crane_selections: breakdown.tender_crane_selections,
              on_site_mobile_crane_breakdown: breakdown
            }
          ),
          turbo_stream.replace("crane_cost_summary",
            partial: "tender_crane_selections/summary",
            locals: { 
              on_site_mobile_crane_breakdown: breakdown
            }
          )
        ]

        # Add missing rates alert if there are missing rates
        alert_frame_id = "on_site_mobile_crane_breakdown_#{breakdown.id}_missing_rates_alert"
        if missing_rates.any?
          updates << turbo_stream.replace(
            alert_frame_id,
            partial: "on_site_mobile_crane_breakdowns/missing_rates_alert",
            locals: { 
              created_count: created_count,
              missing_rates: missing_rates
            }
          )
        else
          # Clear alert if all rates were found
          updates << turbo_stream.replace(
            alert_frame_id,
            partial: "on_site_mobile_crane_breakdowns/missing_rates_alert",
            locals: { 
              created_count: created_count,
              missing_rates: []
            }
          )
        end

        render turbo_stream: updates
      end
    end
  end

  # POST /tenders/:tender_id/ensure_breakdown
  def ensure_breakdown
    @tender = Tender.find(params[:tender_id])
    @breakdown = @tender.on_site_mobile_crane_breakdown || @tender.create_on_site_mobile_crane_breakdown
    redirect_to builder_on_site_mobile_crane_breakdown_path(@breakdown), notice: "Breakdown ready for configuration."
  end

  # GET /on_site_mobile_crane_breakdowns/new
  def new
    @on_site_mobile_crane_breakdown = OnSiteMobileCraneBreakdown.new
  end

  # GET /on_site_mobile_crane_breakdowns/1/edit
  def edit
  end

  # POST /on_site_mobile_crane_breakdowns or /on_site_mobile_crane_breakdowns.json
  def create
    @on_site_mobile_crane_breakdown = OnSiteMobileCraneBreakdown.new(on_site_mobile_crane_breakdown_params)

    respond_to do |format|
      if @on_site_mobile_crane_breakdown.save
        format.html { redirect_to @on_site_mobile_crane_breakdown, notice: "On site mobile crane breakdown was successfully created." }
        format.json { render :show, status: :created, location: @on_site_mobile_crane_breakdown }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @on_site_mobile_crane_breakdown.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /on_site_mobile_crane_breakdowns/1 or /on_site_mobile_crane_breakdowns/1.json
  def update
    respond_to do |format|
      if @on_site_mobile_crane_breakdown.update(on_site_mobile_crane_breakdown_params)
        format.html { redirect_to @on_site_mobile_crane_breakdown, notice: "On site mobile crane breakdown was successfully updated.", status: :see_other }
        format.turbo_stream { render turbo_stream: turbo_stream.replace(@on_site_mobile_crane_breakdown, partial: "on_site_mobile_crane_breakdown", locals: { on_site_mobile_crane_breakdown: @on_site_mobile_crane_breakdown }) }
        format.json { render :show, status: :ok, location: @on_site_mobile_crane_breakdown }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.turbo_stream { render turbo_stream: turbo_stream.replace(@on_site_mobile_crane_breakdown, partial: "on_site_mobile_crane_breakdown", locals: { on_site_mobile_crane_breakdown: @on_site_mobile_crane_breakdown }) }
        format.json { render json: @on_site_mobile_crane_breakdown.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /on_site_mobile_crane_breakdowns/1 or /on_site_mobile_crane_breakdowns/1.json
  def destroy
    @on_site_mobile_crane_breakdown.destroy!

    respond_to do |format|
      format.html { redirect_to on_site_mobile_crane_breakdowns_path, notice: "On site mobile crane breakdown was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_on_site_mobile_crane_breakdown
      @on_site_mobile_crane_breakdown = OnSiteMobileCraneBreakdown.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def on_site_mobile_crane_breakdown_params
      params.require(:on_site_mobile_crane_breakdown).permit(:tender_id, :total_roof_area_sqm, :erection_rate_sqm_per_day, :ownership_type, :splicing_crane_required, :splicing_crane_size, :splicing_crane_days, :misc_crane_required, :misc_crane_size, :misc_crane_days)
    end
end
