# stripe managed account class handles invidual and company managed account creating and updating
# it accepts 2 parameter user and params where user is current user and params is from partialform _managed
# NOTE constants in this class are immutable. elements of array cannot be modified. If you want to change remove .freeze
class StripeManagedAccountService < Struct.new( :user, :params )

  # this countries has common params to send for creating manged individual/company account
  COMMON_COUNTRIES = %W(AT FI FR IT LU NL NO PT IE ES SE BE DK DE US AU GB).freeze

  # US has routing number AU and GB has also routing number internally named as account number
  ROUTING_COUNTRIES = %W(US AU GB).freeze; BANK_CODE_COUNTRIES = %W(SG CA HK).freeze

  # creates stripe managed and individual account
  def create_account
    # managed_account is a string hold same as function name which is dynamic
    managed_account = "#{string_method_name}_#{params_org_type}_account"
    # create managed individual and company account self.send method accepts parameter and calls function
    account = Stripe::Account.create(send(managed_account))
  rescue => e; e # returns error object to retrieve error message is e.message. handle stripe create account error
  end

  # creates external account after creation of account. account paramete is send from module additiona_user_Action
  def create_external_account(account)
    # external_accounts is a string which hold same name as function declare above
    external_accounts = "#{string_method_name}_external_accounts"
    # calls dynamic function name with send method and creates external accounts
    account.external_accounts.create(send(external_accounts))
     # this is temporary link for debugging purpose
    "<a href='https://dashboard.stripe.com/test/applications/users/"+ account.id + "'>Stripe Connected Succesfull Click for dashboard page</a>"
  rescue => e; e # error object contains message attribute
  end

  # private functions
  private

  # address function returns hash address_attributes from params so that it will be convinient to use hash
  def address; params[:address_attributes]; end

  # stripe cred returns stripe cred hash
  def stripe_cred; params[:stripe_creds_attributes]['0']; end

  # returns people hash
  def people; params[:people_attributes]['0']; end

  # returns bank account hash
  def bank_account; params[:bank_accounts_attributes]['0']; end

  # returns people hash
  def people_address; params[:people_attributes]['0']['address_attributes']; end

  # country with bank code are countries in constant BANK_CODE_COUNTRIES
  def country_with_bank_code_individual_account; common_individual_account; end

  # org_type comes in upcase as a params but stripe need in downcase
  def params_org_type; params[:org_type].downcase; end

  # returns common company account hash for countries in constant common_countries
  def common_company_account
    company_account = managed_company_account
    # for finland stripe complains to send 8 digit ssn/personal_id. it is not require
    company_account[:legal_entity].delete(:personal_id_number) if address[:country] == 'FI'
    company_account # return modified hash if condition met
  end

  # return string method name
  def string_method_name
    return 'common' if COMMON_COUNTRIES.include?(address[:country])
    return 'country_with_bank_code' if BANK_CODE_COUNTRIES.include?(address[:country])
  end

  def country_with_bank_code_external_accounts;
    bank_code_countries = basic_external_accounts
    bank_code_countries[:external_account].merge( { bank_code: bank_account[:institution_number]  } )
    bank_code_countries
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

  # return hash for creating external_bank_account for managed individual and company account
  def basic_external_accounts
    { external_account: { object: 'bank_account', country: bank_account[:country],
                                                  currency: bank_account[:currency],
                                                  account_number: bank_account[:account_number],
                                                  routing_number: bank_account[:routing_number],
                                                  account_holder_type: params[:org_type],
                                                  account_holder_name: user.first_name,
                                                  supported_bank_account_currencies: {
                                                  bank_account[:currency]=> [ bank_account[:country] ] }

                        }
    }
  end

  # required hash is prepared as mention in the sripe documentation.Please follow below link.
  # https://stripe.com/docs/api#account_object
  # TODO function is too lengthy feel free to make small without changing its behaviour. We do not have test
  def managed_company_account
    dob = people[:dob].split('/')
    { managed: true, country: address[:country], email: user.email, business_url: params[:url],
      business_name: params[:org_name], product_description: params[:description],
      tos_acceptance: { ip: stripe_cred[:ip], date: Time.current.to_i, user_agent: stripe_cred[:user_agent] },
      legal_entity: { type: params_org_type, first_name: user.first_name, last_name: user.last_name,
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
