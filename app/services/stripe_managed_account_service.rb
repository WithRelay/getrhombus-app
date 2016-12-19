# stripe managed account class handles invidual and company managed account creating and updating
# Accepts parameter user and params where user is current user and params is from partialform _managed
# NOTE constants in this class are immutable. elements of array cannot be modified. If you want to change remove .freeze
class StripeManagedAccountService < Struct.new( :user, :params )

  # this countries has common params to send for creating manged individual/company account
  COMMON_COUNTRIES = %W(AT FI FR IT LU NL NO PT IE ES SE BE DK DE US AU GB).freeze

  # US has routing number AU and GB has also routing number internally named as account number
  ROUTING_COUNTRIES = %W(US AU GB).freeze; BANK_CODE_COUNTRIES = %W(SG CA HK).freeze

  # since we are not accessing contant outside of a class so making private all constants
  private_constant :ROUTING_COUNTRIES, :BANK_CODE_COUNTRIES, :COMMON_COUNTRIES

  # sets api version for connect account it needs recent 2014-12-17 plus version
  # see https://stripe.com/docs/connect/managed-accounts for details
  Stripe.api_version = '<redacted_phone_number>'

  # creates stripe managed and individual account
  def create_account
    # create managed individual and company account self.send method accepts parameter and calls function
    account = Stripe::Account.create(send(string_method_name))
  rescue Stripe::StripeError => e; e
  rescue StandardError => e; e # returns error object to retrieve error message is e.message. handle stripe create account error
  end

  # creates external account after creation of account. account parameter is send from module additiona_user_Action
  def create_external_account(account)
    # calls dynamic function name with send method and creates external accounts
    bank_account = account.external_accounts.create(send(external_string_method_name))
    bank_account
  rescue Stripe::StripeError => e; e
  rescue StandardError => e; e # error object contains message attribute
  end

  def update_account_email
    account = retrieve_account
    account.update_attributes({ email: user.email })
    account.save
  rescue Stripe::StripeError => e; e
  rescue StandardError => e; e
  end

  def update_account
    # NOTE while updating account attributes falls in legal_entity cannot be updated
    account = retrieve_account
    account.update_attributes(send("update_#{params_org_type}_managed_account"))
    account.save
  rescue Stripe::StripeError => e; e
  rescue StandardError => e; e
  end

  def check_update_or_create(account)
    if user.bank_accounts.find(bank_account[:id]).stripe_bank_account_id.present?
      update_external_accounts(account)
    else
      create_external_account(account)
    end
  end

  # private functions
  private
  # bank_accounts metadata are only editable other bank_details are not editable by design
  # https://stripe.com/docs/api#account_update_bank_account
  def update_external_accounts(account)
    bank_account = account.external_accounts.retrieve(user.bank_accounts[0].stripe_bank_account_id)
    bank_account.update_attributes(send(external_string_method_name))
    bank_account.save
    bank_account
  rescue Stripe::StripeError => e; e
  rescue StandardError => e; e
  end


  def retrieve_account; Stripe::Account.retrieve(user.stripe_creds[0].account_id) end

  # address function returns hash address_attributes from params so that it will be convinient to use hash
  def address; params[:address_attributes] end

  # stripe cred returns stripe cred hash
  def stripe_cred; params[:stripe_creds_attributes]['0'] end

  # returns people hash
  def people; params[:people_attributes]['0'] end

  # returns bank account hash
  def bank_account; params[:bank_accounts_attributes]['0'] end

  # returns people hash
  def people_address; params[:people_attributes]['0']['address_attributes'] end

  # country with bank code are countries in constant BANK_CODE_COUNTRIES
  def country_with_bank_code_individual_account; common_individual_account end

  def country_with_bank_code_company_account; common_individual_account end

  # org_type comes in upcase as a params but stripe need in downcase
  def params_org_type; params[:org_type].downcase end

  def common_country_present?; COMMON_COUNTRIES.include?(address[:country]) end

  def bank_code_country_present?; BANK_CODE_COUNTRIES.include?(address[:country]) end

  # returns common company account hash for countries in constant common_countries
  def common_company_account
    company_account = managed_company_account
    # for finland stripe complains to send 8 digit ssn/personal_id. it is not require
    company_account[:legal_entity].delete(:personal_id_number) if address[:country] == COMMON_COUNTRIES[1]
    company_account # return modified hash if condition met
  end

  # return string method name
  def string_method_name
    # returns a string hold same as function name which is dynamic
    return "common_#{params_org_type}_account" if common_country_present?
    return "country_with_bank_code_#{params_org_type}_account" if bank_code_country_present?
  end

  def external_string_method_name
    # external_accounts is a string which hold same name as function declare above
    return "common_external_accounts" if common_country_present?
    return "country_with_bank_code_external_accounts" if bank_code_country_present?
  end

  def country_with_bank_code_external_accounts
    bank_code_countries = basic_external_accounts
    bank_code_countries[:external_account].merge( { bank_code: bank_account[:institution_number]  } )
    bank_code_countries[:external_account][:routing_number] = routing_number_bank_code_countries
    bank_code_countries
  end

  def routing_number_bank_code_countries
    bank_code_external = basic_external_accounts[:external_account][:routing_number]
    if  BANK_CODE_COUNTRIES[1] == address[:country]
      bank_code_external + bank_account[:institution_number]
    else
      "#{bank_code_external}-#{bank_account[:institution_number]}" if  BANK_CODE_COUNTRIES[1] != address[:country]
    end
  end

  def common_external_accounts
    external_account = basic_external_accounts
    # for countries in constant COMMON_COUNTRIES routing number params is not required
    external_account[:external_account].delete(:routing_number) unless ROUTING_COUNTRIES.include?(bank_account[:country])
    external_account
  end

  def common_individual_account
    individual_account = managed_company_account
    individual_account.delete(:business_name) # for individual account business name i.e. legal name is not required
    individual_account
  end

  def update_individual_managed_account
    update_in_account = update_company_managed_account
    update_in_account.delete(:business_name)
    update_in_account
  end

  def update_company_managed_account
    update_company = managed_company_account
    update_company.except!(:managed, :country, :product_description)
    update_company
  end

  # return hash for creating external_bank_account for managed individual and company account
  def basic_external_accounts
    { external_account: { object: 'bank_account', country: bank_account[:country],
                                                  currency: bank_account[:currency],
                                                  account_number: bank_account[:account_number],
                                                  routing_number: bank_account[:routing_number],
                                                  account_holder_type: params[:org_type],
                                                  account_holder_name: people[:full_name]
                        }
    }
  end

  # returns additional owner hash as mention in https://stripe.com/docs/api#account_object
  # creates additional owner params which will be array and includes multiple hashes with
  # additional owner attributes details like first_name, last_name
  # TODO Need refactor in future function is lengthy.
  def additional_owners
    additional_owner = []
    params[:people_attributes].each do |key, value|
      unless key == '0' # key 0 contains address for default legal entities not for additional owners address
        owner_details = {}
        dob = value[:dob].present? ? value[:dob].split('-') : []
        full_name = value[:full_name].present? ? value[:full_name].split(' ', 2) : []
        owner_details[:first_name] = full_name[0]
        owner_details[:last_name] = full_name[1]
        owner_details[:dob] = { day: dob[2], month: dob[1], year: dob[0] }
        address = value[:address_attributes]
        owner_details[:address] = { city: address[:city], country: address[:country],
                                    state: address[:state_province], postal_code: address[:postal_code],
                                    line1: address[:street_address]
                                  }
        additional_owner.push(owner_details);
      end
    end if params[:people_attributes].keys.length > 1
    additional_owner
  end

  # required hash is prepared as mention in the sripe documentation.Please follow below link.
  # https://stripe.com/docs/api#account_object
  # TODO function is too lengthy feel free to make small without changing its behaviour. We do not have test
  def managed_company_account
    dob = people[:dob].present? ? people[:dob].split('-') : []
    full_name = people[:full_name].present? ? people[:full_name].split(' ', 2) : []
    { email: user.email, business_url: params[:url],
      business_name: params[:org_name], managed: true, country: address[:country],
      product_description: params[:description],
      tos_acceptance: { ip: stripe_cred[:ip], date: stripe_cred[:tos_date].to_i, user_agent: stripe_cred[:user_agent] },
      legal_entity: { type: params_org_type, first_name: full_name[0], last_name: full_name[1],
                      gender: people[:gender],  phone_number: user.phone_number, business_name: people[:business_name],
                      business_tax_id: params[:org_tax_id], personal_id_number: people[:last4],
                      personal_address: { city: people_address[:city],
                                          country: people_address[:country],
                                          postal_code: people_address[:postal_code],
                                          state: people_address[:state_province],
                                          line1: people_address[:street_address]
                                        },
                      dob: { day: dob[2], month: dob[1], year: dob[0] },
                      address: { state: address[:state_province], postal_code: address[:postal_code],
                                 city: address[:city], line1: address[:street_address]
                               },
                      address_kana: {}, address_kanji: {}, personal_address_kana: {}, personal_address_kanji: {},
                      verification: {}, ssn_last_4_provided: {}, business_tax_id_provided: {},
                      business_vat_id_provided: {}, personal_id_number_provided: {},
                      additional_owners: additional_owners
                    }
    }
  end
end
