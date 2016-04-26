module MakeSpreadsheet
  extend ActiveSupport::Concern

  def create_spreadsheet(user_id, user_level, start_date, end_date)
		begin
			txn = Transaction.where("user_id = ? AND created_at BETWEEN ? AND ?", user_id, start_date, end_date)

		  book = Spreadsheet::Workbook.new
		  sheet1 = book.create_worksheet :name => 'Transactions'
			sheet1.row(0).default_format = Spreadsheet::Format.new :horizontal_align => :centre, :weight => :bold
		  sheet1.row(0).concat ["Date (GMT)", "Transaction ID", "From", "To", "Amount", "Amount Less Fees", "Currency"] if user_level == 1
		  sheet1.row(0).concat ["Date (GMT)", "Transaction ID", "From", "To", "Amount", "Currency"] if user_level == 0
			
			format = Spreadsheet::Format.new :horizontal_align => :left
			txn.each.with_index(1) do |t,i|
				sheet1.row(i).push t.created_at, t.transaction_number, t.from, t.to, t.amount.to_f, t.amount_less_fees.to_f, t.currency if user_level == 1
				sheet1.row(i).push t.created_at, t.transaction_number, t.from, t.to, t.amount.to_f, t.currency if user_level == 0
				sheet1.row(i).default_format = format
			end

			file_contents = StringIO.new
			book.write file_contents
			return file_contents.string
		rescue StandardError => err
			# email us here
			return false
		end
  end

  def customer_info_xls_template
  	begin
		  book = Spreadsheet::Workbook.new
		  sheet1 = book.create_worksheet :name => 'Customer Info'
			sheet1.row(0).default_format = Spreadsheet::Format.new :horizontal_align => :centre, :weight => :bold
		  sheet1.row(0).concat ["Email", "Phone (Ex. <redacted_phone_number>)", "First Name", "Last Name"]
			file_contents = StringIO.new
			book.write file_contents
			return file_contents.string
		rescue StandardError => err
			# email us here
			return false
		end
  end


end