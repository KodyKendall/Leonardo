class LlamaMailer < ApplicationMailer
  def send_email(to:, subject:, body:, from:)
    @body = body
    mail(to: to, subject: subject, from: from)
  end
end
