class ClientsController < ApplicationController
  before_action :set_client, only: %i[ show edit update destroy contacts ]

  # GET /clients or /clients.json
  def index
    authorize Client
    @clients = Client.order(:business_name)
    
    # API endpoint for searchable dropdown
    if request.xhr? || params[:format] == 'json'
      query = params[:q].to_s.strip.downcase
      clients = if query.present?
        Client.where("LOWER(business_name) LIKE ?", "%#{query}%").order(:business_name).limit(10)
      else
        Client.order(:business_name).limit(10)
      end
      render json: clients.map { |c| { id: c.id, text: c.business_name } }
    end
  end

  # GET /clients/1 or /clients/1.json
  def show
    authorize @client
  end

  # GET /clients/1/contacts.json
  def contacts
    authorize @client
    respond_to do |format|
      format.json do
        contacts = @client.contacts.map do |contact|
          {
            id: contact.id,
            name: contact.name,
            email: contact.email,
            phone: contact.phone,
            is_primary: contact.is_primary
          }
        end
        render json: contacts
      end
    end
  end

  # GET /clients/new
  def new
    authorize Client
    @client = Client.new
  end

  # GET /clients/1/edit
  def edit
    authorize @client
  end

  # POST /clients or /clients.json
  def create
    @client = Client.new(client_params)
    authorize @client

    respond_to do |format|
      if @client.save
        format.html { redirect_to @client, notice: "Client was successfully created." }
        format.json { render json: { id: @client.id, text: @client.business_name }, status: :created }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @client.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /clients/1 or /clients/1.json
  def update
    authorize @client
    respond_to do |format|
      if @client.update(client_params)
        format.html { redirect_to @client, notice: "Client was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @client }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @client.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /clients/1 or /clients/1.json
  def destroy
    authorize @client
    @client.destroy!

    respond_to do |format|
      format.html { redirect_to clients_path, notice: "Client was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_client
      @client = Client.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def client_params
      params.require(:client).permit(
        :business_name,
        :contact_name,
        :contact_email,
        contacts_attributes: [:id, :name, :email, :phone, :is_primary, :_destroy]
      )
    end
end
