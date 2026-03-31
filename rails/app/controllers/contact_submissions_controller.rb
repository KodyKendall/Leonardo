class ContactSubmissionsController < ApplicationController
  skip_before_action :authenticate_user!

  def create
    @contact_submission = ContactSubmission.new(contact_submission_params)

    respond_to do |format|
      if @contact_submission.save
        format.html { redirect_to root_path, notice: "Thank you for your submission. We'll be in touch shortly!" }
        format.turbo_stream
      else
        format.html { redirect_to root_path, alert: "There was an error with your submission. Please try again." }
        format.turbo_stream { render :create, status: :unprocessable_entity }
      end
    end
  end

  private

  def contact_submission_params
    params.require(:contact_submission).permit(:company_name, :first_name, :last_name, :title, :email, :attachment)
  end
end