namespace :recipients do
  namespace :staging do
    desc 'refresh all recipients on test pagarme'
    task refresh_recipients: :environment do
      raise 'Only on staging env' unless Rails.env.staging?

      Recipient.find_each do |recipient|
        begin
          PagarMe::Recipient.find recipient.pagarme_recipient_id
        rescue PagarMe::NotFound
          bank_account = recipient.recipient["bank_account"]
          new_pagarme_recp = PagarMe::Recipient.create(
            bank_account: {
              bank_code:       bank_account["bank_code"],
              agencia:         bank_account["agencia"],
              agencia_dv:      bank_account["agencia_dv"],
              conta:           bank_account["conta"],
              conta_dv:        bank_account["conta_dv"],
              legal_name:      bank_account["legal_name"],
              document_number: bank_account["document_number"]
            },
            transfer_enabled: false
          )

          created = Recipient.create!(
            community_id: recipient.community_id,
            recipient: new_pagarme_recp.to_json,
            pagarme_recipient_id: new_pagarme_recp.id,
            transfer_day: recipient.transfer_day,
            transfer_enabled: recipient.transfer_enabled
          )
          recipient.community.update_attribute(:recipient_id, created.id)

          puts "created recipient #{created.pagarme_recipient_id}"
        end
      end
    end
  end
end