namespace :db do
  desc "Truncate all tables"
  task :truncate => :environment do
    conn = ActiveRecord::Base.connection
    tables = conn.execute("show tables").map { |r| r[0] }
    tables.delete "schema_migrations"
    tables.delete "people"
    tables.delete "api_creds"
    tables.delete "merchant_customers"
    tables.delete "users"
    tables.delete "away_messages"
    tables.each { |t| conn.execute("TRUNCATE #{t}") }
  end
end