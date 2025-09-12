# app/models/twilio.rb
require "twilio-ruby"

module TwilioService
  extend self   # allows calling methods directly, e.g. TwilioService.send_text

  def send_text(number, message, twilio_number = "")
    account_sid   = ENV["TWILIO_SID"]
    auth_token    = ENV["TWILIO_AUTH"]
    client        = Twilio::REST::Client.new(account_sid, auth_token)
    twilio_number = twilio_number.present? ? twilio_number : ENV["TWILIO_NUMBER"]

    client.messages.create(
      from: twilio_number,
      to:   number,
      body: message
    )
  end

  def internationalize(number)
    number.start_with?("+1") ? number : "+1#{number}"
  end

  def strip_internationalize(number)
    number.start_with?("+1") ? number[2..] : number
  end

  def purchase_available_phone_number(phone_number_to_purchase, organization, test_mode)
    client = get_client

    unless test_mode
      client.incoming_phone_numbers.create(
        phone_number: phone_number_to_purchase,
        friendly_name: "RUBY AI HACKATHON: #{organization.name}"
      )

      organization.update(twilio_number: phone_number_to_purchase)
    end

    set_up_messaging_and_call_url(phone_number_to_purchase, ENV["BASE_URL"])
  end

  def set_up_messaging_and_call_url(phone_number, base_url)
    client = get_client
    intl   = internationalize(phone_number)

    matching = client.incoming_phone_numbers.list.find do |record|
      record.phone_number.gsub(/\D/, "") == intl.gsub(/\D/, "")
    end

    if matching
      matching.update(
        voice_url: "#{base_url}/inbound_call",
        sms_url:   "#{base_url}/inbound_sms"
      )
      begin
        setup_messaging_service_campaign(matching.sid, ENV["TWILIO_A2P_CAMPAIGN"], client)
      rescue => e
        Rails.logger.error "Error setting up messaging service campaign: #{e.message}"
      end
    end

    matching&.sid
  end

  def setup_messaging_service_campaign(phone_number_sid, campaign_sid, client)
    client.messaging
          .v1
          .services(campaign_sid)
          .phone_numbers
          .create(phone_number_sid: phone_number_sid)
  end

  def get_messaging_and_call_url(phone_number)
    client = get_client
    intl   = internationalize(phone_number)

    matching = client.incoming_phone_numbers.list.find { |r| r.phone_number == intl }
    [matching&.sms_url, matching&.voice_url]
  end

  def find_available_phone_numbers(area_code)
    client = get_client

    local = client.available_phone_numbers("US").local.list(
      area_code: area_code,
      limit:     8
    )

    local.map { |l| { number: l.friendly_name, city: l.locality, zip: l.postal_code } }
  end

  def get_client
    Twilio::REST::Client.new(ENV["TWILIO_SID"], ENV["TWILIO_AUTH"])
  end

  def verify_account_sid(sid)
    ENV["TWILIO_SID"] == sid
  end

  def parse_incoming_request(to, from)
    destination = strip_internationalize(to)
    source      = strip_internationalize(from)

    org = User.find_by(twilio_number: destination)
    return nil unless org

    [org, destination, source]
  end
end
