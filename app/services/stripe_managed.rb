class StripeManaged < Struct.new( :user, :params )
  def create_account
    begin
      account = Stripe::Account.create(stripe_request_hash)
    rescue => e
       e.message
    end
  end

  def create_external_account(account)
    begin
      account.external_accounts.create(external_accounts)
    rescue => e
      e.message
    end
  end

  private

  def address; params[:address_attributes]; end

  def stripe_cred; params[:stripe_creds_attributes]['0']; end

  def people; params[:people_attributes]['0']; end

  def bank_account; params[:bank_accounts_attributes]['0']; end

  def external_accounts
    { external_account: { object: 'bank_account', country: bank_account[:country],
                                                  currency: bank_account[:currency],
                                                  account_number: bank_account[:account_number],
                                                  routing_number: bank_account[:routing_number],
                                                  account_holder_type: params[:org_type],
                                                  account_holder_name: user.first_name

                        }
    }
  end

  # required hash as mention in the sripte documentation.Please follow below link.
  # https://stripe.com/docs/api#account_object
  def stripe_request_hash
    dob = people[:dob].split('/')
    { managed: true, country: address[:country], email: user.email, business_url: params[:url],
      business_name: params[:org_name],
      tos_acceptance: { ip: stripe_cred[:ip], date: Time.now.to_i, user_agent: stripe_cred[:user_agent] },
      legal_entity: { type: params[:org_type].downcase, first_name: user.first_name, last_name: user.last_name,
                      business_tax_id: true,
                      dob: { day: dob[1], month: dob[0], year: dob[2] }, business_name: params[:org_name],
                      address: { state: address[:state_province], postal_code: address[:postal_code],
                                 city: address[:city], line1: address[:street_address]
                               }
                    }
    }
  end
end
