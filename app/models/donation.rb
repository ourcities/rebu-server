require 'pagarme'

class Donation < ActiveRecord::Base
  belongs_to :widget
  has_one :mobilization, through: :widget
  has_one :organization, through: :mobilization

  after_create :create_transaction
  after_create :send_mail

  def new_transaction
    PagarMe::Transaction.new({
      :card_hash => self.card_hash,
      :amount => self.amount,
      :payment_method => self.payment_method,
      :split_rules => split_rules,
      :metadata => {
        :widget_id => self.widget.id,
        :mobilization_id => self.mobilization.id,
        :organization_id => self.organization.id,
        :city => self.organization.city,
        :email => self.email }
    })
  end

  def create_transaction
    self.transaction do
      @transaction = new_transaction
      self.email = @transaction["customer"]["email"]
      self.save

      begin
        @transaction.charge

        if self.payment_method == 'boleto' && Rails.env.production?
          @transaction.collect_payment({email: self.email})
        end
      rescue PagarMe::PagarMeError => e
        logger.error("\n==> DONATION ERROR: #{e.inspect}\n")
      end
    end
  end

  def split_rules
    organization_sr = PagarMe::SplitRule.new(organization_rule)
    city_sr = PagarMe::SplitRule.new(city_rule)

    [organization_sr, city_sr]
  end

  def organization_rule
    recipient = Organization.find_by_name("Nossas Cidades").pagarme_recipient_id
    { charge_processing_fee: true, liable: false, percentage: 15, recipient_id: recipient
    }
  end

  def city_rule
    recipient = self.organization.pagarme_recipient_id
    { charge_processing_fee: false, liable: true, percentage: 85, recipient_id: recipient }
  end

  def send_mail
    begin
      DonationsMailer.thank_you_email(self).deliver_later!
    rescue StandardError => e
      logger.error("\n==> ERROR SENDING DONATION EMAIL: #{e.inspect}\n")
    end
  end

  def client
    PagarMe.api_key = ENV["PAGARME_API_KEY"]
  end
end
