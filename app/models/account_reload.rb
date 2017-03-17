class AccountReload < ActiveRecord::Base
	enum origin: [ :system, :merchant ]
end
