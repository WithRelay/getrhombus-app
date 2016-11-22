class StripeManagedAccountService < Struct.new( :user, :params )

  # this countries has common params to send
  COMMON_COUNTRIES = %W(AT FI FR IT LU NL NO PT ES SE BE DK DE US AU).freeze

  # us and au has only field routing number to send
  DEFAULT_COUNTRIES = %W(US AU).freeze

  def create_account
    managed_account = "#{country_name}_managed_account"
    account = Stripe::Account.create(self.send(managed_account))
  rescue => e
    e.message
  end

  def create_external_account(account)
    external_accounts = "#{country_name}_external_accounts"
    account.external_accounts.create(self.send(external_accounts))
  rescue => e
    e.message
  end

  private

  def address; params[:address_attributes]; end

  def stripe_cred; params[:stripe_creds_attributes]['0']; end

  def people; params[:people_attributes]['0']; end

  def bank_account; params[:bank_accounts_attributes]['0']; end

  def people_address; params[:people_attributes]['0']['address_attributes']; end

  def common_managed_account; managed_company_account; end

  def country_name
    COMMON_COUNTRIES.include?(address[:country]) ? 'common' : authorized_country_list[address[:country].to_sym]
  end

  def authorized_country_list
    country_list = {}
    PaymentService.stripe_country_list.each{ |k, v| country_list[k] = v[0].split(' ').join('_').downcase}
    country_list
  end

  def common_external_accounts
    external_account = basic_external_accounts
    external_account[:external_account].merge!({ supported_bank_account_currencies: {
                                                         bank_account[:currency]=> [ bank_account[:country] ]
                                                        }
                                                        })
    DEFAULT_COUNTRIES.include?(address[:country]) unless external_account[:external_account].delete(:routing_number)
    external_account
  end

  def basic_external_accounts
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
  def managed_company_account
    dob = people[:dob].split('/')
    { managed: true, country: address[:country], email: user.email, business_url: params[:url],
      business_name: params[:org_name], product_description: params[:description],
      tos_acceptance: { ip: stripe_cred[:ip], date: Time.now.to_i, user_agent: stripe_cred[:user_agent] },
      legal_entity: { type: params[:org_type].downcase, first_name: user.first_name, last_name: user.last_name,
                      business_tax_id: params[:org_tax_id], personal_id_number: people[:last4],
                      personal_address: { city: people_address[:city],
                                          country: people_address[:country],
                                          postal_code: people_address[:postal_code],
                                          state: people_address[:state_province],
                                          line1: people_address[:street_address]
                                        },
                      dob: { day: dob[1], month: dob[0], year: dob[2] }, business_name: params[:org_name],
                      address: { state: address[:state_province], postal_code: address[:postal_code],
                                 city: address[:city], line1: address[:street_address]
                               }
                    }
    }
  end
end
