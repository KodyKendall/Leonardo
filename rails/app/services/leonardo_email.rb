module LeonardoEmail
  extend self

  DEFAULT_FROM = "Leonardo <leonardo@llamapress.ai>"

  def send(to:, subject:, body:, from: DEFAULT_FROM)
    LlamaMailer.send_email(to: to, subject: subject, body: body, from: from).deliver_now
  end
end
