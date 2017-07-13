module UsersHelper

  def login_user_type
    current_user.is_merchant? ? 'merchant' : 'customer'
  end

  def get_time_zone_lists
    ActiveSupport::TimeZone::MAPPING.map{ |z| [z.first, z.first] }.sort {|x,y| x[0] <=> y[0]}
  end

  def business_type_list
    { 'Organization' => 'Company', 'Individual' => 'Individual' }
  end

  def business_categories
    {
      'Beauty & Spas' => 'Beauty & Spas',
      'Charity' => 'Charity',
      'Cleaning Service' => 'Cleaning Service',
      'Coffee Shop' => 'Coffee Shop',
      'Concierge Services' => 'Concierge Services',
      'Ecommerce' => 'Ecommerce',
      'Education (K-12)' => 'Education (K-12)',
      'Education (Universities & Colleges)' => 'Education (Universities & Colleges)',
      'Financial Services' => 'Financial Services',
      'Home & Repair Services' => 'Home & Repair Services',
      'Hotel & Travel' => 'Hotel & Travel',
      'Health & Fitness' => 'Health & Fitness',
      'Individual' => 'Individual',
      'Local Services' => 'Local Services',
      'Non Profit' => 'Non Profit',
      'On-demand Delivery' => 'On-demand Delivery',
      'Pets' => 'Pets',
      'Professional Services' => 'Professional Services',
      'Religious Organization' => 'Religious Organization',
      'Restaurant' => 'Restaurant',
      'Retail' => 'Retail',
      'Taxi & Limousine' => 'Taxi & Limousine',
      'Other' => 'Other'
    }
  end

  def twilio_countries
    TextingService.twilio_list.keys.map do |k|
      [TextingService.twilio_list[k][:name], k]
    end
  end

  def rhombus_for
    ['Customer Support', 'Sales', 'Marketing', 'Payments']
  end

  def select_team_size
    ['1 - 5 employees', '6 - 20 employees', '21 - 50 employees', '51 - 100 employees',
    '101 - 200 employees', '201 - 500 employees', '501 - 1000 employees',
    '1001 - 3000 employees', '3001 - 5000 employees', '5000+ employees']
  end

  def exp_date
    (current_user.exp_month.present? && current_user.exp_year.present?) ? "#{current_user.exp_month}/#{current_user.exp_year}" : ""
  end

  def stripe_standalone_cred
    current_user.standalone_stripe_cred
  end

  def country_list
    CountriesList::COUNTRIES_LIST.collect { |c| [ c[:name], c[:code] ] }
  end

  def message_graph
    if @dashboard_messages_data[:msg_30_days][:chart_data].empty?
      htm = '<div class= "no-chart-data">
      <p class="empty-view-short-paragraph">No data. '
      htm += link_to('Send your first message', user_conversations_path(current_user), class: 'links' ).to_s
      htm += ' to view chart activity</p></div>'
      htm.html_safe
    else
      area_chart @dashboard_messages_data[:msg_30_days][:chart_data],
        library: {
          scales: {
            xAxes: [{
              ticks: {
                autoSkip: false,
                minRotation: 60
              },
              time: {
                unit: 'day',
                displayFormats: {
                  maxRotation: 60,
                  'day': 'MMM D'
                },
              }
            }]
          }
        },
        curve: false
      end
  end

  def transactions_graph
    if current_user.get_stripe_cred[:type].nil?
      htm = '<div class="no-chart-data transactions"><p class="empty-view-short-paragraph">No data. '
      htm += link_to('Connect your bank account', user_bank_accounts_path(current_user), class: "links").to_s
      htm += '&nbsp;to view chart activity</p></div>'
      htm.html_safe
    elsif @dashboard_transactions[:tranc_chart_data].empty?
      htm = '<div class="no-chart-data transactions"><p class="empty-view-short-paragraph">No data. '
      htm += link_to('Charge a customer', user_transactions_path(current_user), class: "links").to_s
      htm += '&nbsp;to view chart activity</p></div>'
      htm.html_safe
    else
      line_chart @dashboard_transactions[:tranc_chart_data], height: "250px",
          library: {
            scales: {
              xAxes: [{
                ticks: {
                  autoSkip: false,
                  maxRotation: 60,
                  minRotation: 60
                },
                time: {
                  unit: 'day',
                  displayFormats: {
                    'day': 'MMM D'
                  },
                }
                }]
              }
            },
            curve: false
    end
  end

  def hosted_sms_status_notice(h)
    if (h.status.downcase == 'completed')
      'Congratulations! Your business phone number has been activated in Relay. You can now receive two-way messages and payments from customers using your existing landline number.'
    elsif (h.status.downcase == 'failed')
      'Unfortunately, we are unable to activate Relay on your existing phone number.'
    elsif (h.status.downcase == 'received' || h.status.downcase == 'pending-verification')
      'Follow the link below to enter the activation code provided by Twilio. Note that the activation code expires after 10 minutes.'
    else
      'Your phone number activation is in progress; this may take up to 2 hours to complete. In the meantime, use the temporary number on your dashboard to get started. We\'ll notify you once your landline is activated'
    end
  end
end
