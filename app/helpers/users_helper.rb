module UsersHelper

  def login_user_type
    current_user.is_merchant? ? 'merchant' : 'customer'
  end

  def get_time_zone_lists
    ActiveSupport::TimeZone::MAPPING.map{ |z| [z.first, z.first] }.sort {|x,y| x[0] <=> y[0]}
  end

  def business_type_list
    ['Business', 'Nonprofit', 'Education', '[K12] Education [University & Colleges]', 'Individual']
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

  def stripe_standalone_cred
    current_user.standalone_stripe_cred
  end

  def country_list
    CountriesList::COUNTRIES_LIST.collect { |c| [ c[:name], c[:code] ] }
  end

  def message_graph
    if @messages_data[:msg_30_days][:chart_data].empty?
      htm = '<div class= "no-chart-data">
      <p class="empty-view-short-paragraph">No data. '
      htm += link_to('Send your first message', user_conversations_path(current_user), class: 'links' ).to_s
      htm += ' to view chart activity</p></div>'
      htm.html_safe
    else
      area_chart @messages_data[:msg_30_days][:chart_data],
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
    if @transactions[:tranc_chart_data].empty?
      htm = '<div class="no-chart-data transactions"><p class="empty-view-short-paragraph">No data.'
      htm += link_to('Connect your bank account',user_bank_accounts_path(current_user), class: "links").to_s
      htm += '&nbsp;to view chart activity</p></div>'
      htm.html_safe
    else
      line_chart @transactions[:tranc_chart_data], height: "250px",
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
end
