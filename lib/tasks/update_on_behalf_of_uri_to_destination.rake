
# TASK -. SKIPPING THIS FOR LATER IN THE FUTURE>

# do this at some point so we can bring our data up to that with stripe

desc "Update all transactions with the old on_behalf_of_uri to destination account"
task :update_on_behalf_of_uri_to_destination_account => :environment do
 
 # seems to apply to only balanced payments
 # also update all status from 1 to succeeded if status is a number 
 # also update txn_available_at  #Time.parse(s).utc.to_i
 # also update fee calculations
end