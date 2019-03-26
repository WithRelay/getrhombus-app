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

  def url1
    person.url1
  end

  def url2
    person.url2
  end

  def url3
    person.url3
  end

  def url4
    person.url4
  end

  def url5
    person.url5
  end

  def url6
    person.url6
  end

  def url7
    person.url7
  end

  def url8
    person.url8
  end

  def url9
    person.url9
  end

  def url10
    person.url10
  end

  def url11
    person.url11
  end

  def url12
    person.url12
  end

  def url13
    person.url13
  end

  def url14
    person.url14
  end

  def url15
    person.url15
  end

  def url16
    person.url16
  end

  def url17
    person.url17
  end

  def url18
    person.url18
  end

  def url19
    person.url19
  end

  def url20
    person.url20
  end
end
