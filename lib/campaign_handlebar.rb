# CampaignHandlebar.new(customer or contact object, merchant object).render(message/email_text)
class CampaignHandlebar < Mustache
  attr_reader :person, :merchant
  def initialize(person, merchant)
    @person = person
    @merchant = merchant
  end

  def first_name
    person.first_name
  end

  def full_name
    person.full_name
  end

  def phone_number
    person.phone_number
  end

  def org_number
    merchant.org_phone
  end

  def org_name
    merchant.org_name
  end

  def org_email
    merchant.email
  end

  def org_address
    address = merchant.address
    if address
      "#{address.street_address} #{address.suite}, #{address.city}, #{address.state_province}, #{address.postal_code}"
    else
      ''
    end
  end
end
