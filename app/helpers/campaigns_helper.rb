module CampaignsHelper
  def list_of_time
    array_of_numbers = (1..12).to_a
    am_numbers = array_of_numbers.map {|x| "#{x} AM"}
    pm_numbers = array_of_numbers.map {|x| "#{x} PM"}
    am_numbers + pm_numbers
  end
end
