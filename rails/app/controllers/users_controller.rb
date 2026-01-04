class UsersController < ApplicationController
  before_action :set_user, only: %i[ show edit update destroy ]

  # GET /users or /users.json
  def index
    @users = User.all
  end

  # GET /users/1 or /users/1.json
  def show
  end

  # GET /users/new
  def new
    @user = User.new
  end

  # GET /users/1/edit
  def edit
  end

  # POST /users or /users.json
  def create
    @user = User.new(user_params)

    respond_to do |format|
      if @user.save
        format.html { redirect_to @user, notice: "User was successfully created." }
        format.json { render :show, status: :created, location: @user }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /users/1 or /users/1.json
  def update
    respond_to do |format|
      if @user.update(user_params)
        format.html { redirect_to @user, notice: "User was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @user }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /users/1 or /users/1.json
  def destroy
    begin
      @user.destroy!
      respond_to do |format|
        format.html { redirect_to users_path, notice: "User was successfully destroyed.", status: :see_other }
        format.json { head :no_content }
      end
    rescue ActiveRecord::RecordNotDestroyed => e
      respond_to do |format|
        format.html { redirect_to users_path, alert: "Cannot delete user: This user has associated records (projects, claims, or BOQs). Please reassign or remove those records first.", status: :see_other }
        format.json { render json: { error: "Cannot delete user with associated records" }, status: :unprocessable_entity }
      end
    end
  end

  # POST /users/:id/generate_profile_pic
  def generate_profile_pic
    @user = User.find(params[:id])
    description = params[:profile_pic_description]
    if description.present?
      begin
        OpenAi.new.generate_image(description, attach_to: @user, attachment_name: :profile_pic)
        respond_to do |format|
          format.html { redirect_to @user, notice: "Profile picture generated!", status: :see_other }
          format.turbo_stream { redirect_to @user, notice: "Profile picture generated!", status: :see_other }
        end
      rescue => e
        Rails.logger.error("Error generating profile picture from OpenAI: #{e.message}")
        respond_to do |format|
          format.html { redirect_to user_path(@user), alert: "Failed to generate image: #{e.message}", status: :see_other }
          format.turbo_stream { redirect_to user_path(@user), alert: "Failed to generate image: #{e.message}", status: :see_other }
        end
      end
    else
      respond_to do |format|
        format.html { redirect_to user_path(@user), alert: "Description can't be blank.", status: :see_other }
        format.turbo_stream { redirect_to user_path(@user), alert: "Description can't be blank.", status: :see_other }
      end
    end
  end

  # GET /users/:id/generate_profile_pic
  def generate_profile_pic_form
    @user = current_user
  end

  # GET /users/:id/generate_bio_audio
  def generate_bio_audio_form
    @user = current_user
  end

  # POST /users/:id/generate_bio_audio
  def generate_bio_audio
    @user = User.find(params[:id])
    bio_text = params[:bio_text]
    if bio_text.present?
      begin
        OpenAi.new.generate_audio(bio_text, attach_to: @user, attachment_name: :bio_audio)
        respond_to do |format|
          format.html { redirect_to @user, notice: "Bio audio generated!", status: :see_other }
          format.turbo_stream { redirect_to @user, notice: "Bio audio generated!", status: :see_other }
        end
      rescue => e
        Rails.logger.error("Error generating bio audio from OpenAI: #{e.message}")
        respond_to do |format|
          format.html { redirect_to user_path(@user), alert: "Failed to generate audio: #{e.message}", status: :see_other }
          format.turbo_stream { redirect_to user_path(@user), alert: "Failed to generate audio: #{e.message}", status: :see_other }
        end
      end
    else
      respond_to do |format|
        format.html { redirect_to user_path(@user), alert: "Bio can't be blank.", status: :see_other }
        format.turbo_stream { redirect_to user_path(@user), alert: "Bio can't be blank.", status: :see_other }
      end
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_user
      @user = current_user
    end

    # Only allow a list of trusted parameters through.
    def user_params
      params.require(:user).permit(:name, :email, :password, :password_confirmation, :profile_pic)
    end
end
