class LlamaMailer < ApplicationMailer
  def contact_notification(submission)
    @submission = submission
    recipients = ['kodyckendall@gmail.com', 'darrendavidspencer@gmail.com']

    mail(
      to: recipients,
      subject: "New Lead: #{@submission.company_name}"
    )
  end

  def send_email(to:, subject:, body:, from:)
    @body = body
    mail(to: to, subject: subject, from: from)
  end
end
