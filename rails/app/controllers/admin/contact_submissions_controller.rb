class Admin::ContactSubmissionsController < Admin::BaseController
  def index
    @contact_submissions = ContactSubmission.order(created_at: :desc)
  end

  def show
    @contact_submission = ContactSubmission.find(params[:id])
  end

  def destroy
    @contact_submission = ContactSubmission.find(params[:id])
    @contact_submission.destroy
    redirect_to admin_contact_submissions_path, notice: "Submission deleted."
  end
end
