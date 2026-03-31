require 'rails_helper'

RSpec.describe "ContactSubmissions", type: :request do
  describe "POST /contact_submissions" do
    let(:valid_params) do
      {
        contact_submission: {
          company_name: "Llama Corp",
          first_name: "Leo",
          last_name: "Llama",
          title: "Chief Happiness Officer",
          email: "leo@llama.com"
        }
      }
    end

    let(:invalid_params) do
      {
        contact_submission: {
          company_name: "",
          first_name: "",
          last_name: "",
          title: "",
          email: "invalid"
        }
      }
    end

    context "with valid parameters" do
      it "creates a new ContactSubmission" do
        expect {
          post contact_submissions_path, params: valid_params
        }.to change(ContactSubmission, :count).by(1)
      end

      it "enqueues a notification email" do
        expect {
          post contact_submissions_path, params: valid_params
        }.to have_enqueued_mail(LlamaMailer, :contact_notification)
      end

      it "responds with a turbo stream for success" do
        post contact_submissions_path, params: valid_params, as: :turbo_stream
        expect(response).to have_http_status(:ok)
        expect(response.content_type).to include("text/vnd.turbo-stream.html")
        expect(response.body).to include("Thank you for your submission")
      end

      it "redirects to root path for HTML response" do
        post contact_submissions_path, params: valid_params
        expect(response).to redirect_to(root_path)
        expect(flash[:notice]).to include("Thank you for your submission")
      end
    end

    context "with invalid parameters" do
      it "does not create a new ContactSubmission" do
        expect {
          post contact_submissions_path, params: invalid_params
        }.to_not change(ContactSubmission, :count)
      end

      it "responds with a turbo stream for failure" do
        post contact_submissions_path, params: invalid_params, as: :turbo_stream
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.content_type).to include("text/vnd.turbo-stream.html")
        expect(response.body).to include("turbo-stream action=\"replace\" target=\"contact_form_container\"")
      end

      it "redirects to root path for HTML response on failure" do
        post contact_submissions_path, params: invalid_params
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to include("There was an error with your submission")
      end
    end
  end
end