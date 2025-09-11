class ImportWorker
	include Sidekiq::Worker


	def perform(file_path, model_name, json_data = nil)
		model_name = model_name.to_s

		if json_data.present?
			data_array = JSON.parse(json_data) rescue []
			import_from_json(data_array, model_name)
		elsif file_path.present?
			import_from_spreadsheet(file_path, model_name)
		else
			Rails.logger.warn("[ImportWorker] no file or json data provided for #{model_name}")
		end

	rescue => e
		Rails.logger.error("[ImportWorker] Error importing #{model_name}: #{e.class}: #{e.message}\n#{e.backtrace.first(10).join("\n")}")
	ensure
		begin
      File.delete(file_path) if file_path.present? && File.exist?(file_path)
    rescue => _; end
	end

	# def perform(file_path, model_name)
	# 	spreadsheet = Roo::Spreadsheet.open(file_path)
	# 	header = spreadsheet.row(1)

	# 	case model_name
	# 	when "Channel One"
	# 		import_channel_one(spreadsheet,header)
	# 	when "Channel Two"
	# 		import_channel_two(spreadsheet,header)
	# 	when "Channel Three"
	# 		import_channel_three(spreadsheet,header)
	# 	when "Channel Four"
	# 		import_channel_four(spreadsheet,header)
	# 	when "Channel Five"
	# 		import_channel_five(spreadsheet,header)
	# 	when "Channel Six"
	# 		import_channel_six(spreadsheet,header)
	# 	else
	# 		Rails.logger.warn("Unknown model: #{model_name}")
	# 	end
	# end


	private


	def import_from_spreadsheet(file_path, model_name)
		spreadsheet = Roo::Spreadsheet.open(file_path)
		header = spreadsheet.row(1).map(&:to_s).map(&:strip)

		validator = FileValidator.new(model_name, header)
		unless validator.valid?
      Rails.logger.warn("[ImportWorker] Invalid headers for #{model_name}: #{validator.error_message}")
      return
    end

    (2..spreadsheet.last_row).each do |i|
			row_hash = Hash[[header, spreadsheet.row(i)].transpose]
			create_record_for(model_name, row_hash)
		end
	end

	def import_from_json(data_array, model_name)
		unless data_array.is_a?(Array) && data_array.any?
			Rails.logger.warn("[ImportWorker] No JSON data to import for #{model_name}")
      return
		end

		header = data_array.first.keys.map(&:to_s).map(&:strip)
		validator = FileValidator.new(model_name, header)
		unless validator.valid?
      Rails.logger.warn("[ImportWorker] Invalid JSON keys for #{model_name}: #{validator.error_message}")
      return
    end

    data_array.each do |row|
    	row_hash = row.transform_keys(&:to_s)
    	create_record_for(model_name, row_hash)
    end
	end

	def create_record_for(model_name, row_hash)
		case model_name
		when "Channel One"
			ChannelOne.create!(
			  transaction_id: row_hash["Transaction ID"],
			  sender_msisdn: row_hash["Sender Msisdn"],
			  transaction_amount: row_hash["Transaction Amount"],
			  transaction_datetime: row_hash["Transaction Date and Time"],
			  transaction_type: row_hash["Transaction Type"],
			  receiver_msisdn: row_hash["Receiver Msisdn"],
			  service_name: row_hash["Service Name"],
			  transaction_status: row_hash["Transaction Status"],
			  reference_number: row_hash["Reference Number"],
			  previous_balance: row_hash["Previous Balance"],
			  post_balance: row_hash["Post Balance"],
			  external_transaction_id: row_hash["external_transaction_id"]
			)
		when "Channel Two"
			ChannelTwo.create!(
			  receipt_no: row_hash["Receipt No."],
			  completion_time: row_hash["Completion Time"],
			  initiation_time: row_hash["Initiation Time"],
			  details: row_hash["Details"],
			  transaction_status: row_hash["Transaction Status"],
			  currency: row_hash["Currency"],
			  paid_in: row_hash["Paid In"],
			  withdrawn: row_hash["Withdrawn"],
			  balance: row_hash["Balance"],
			  reason_type: row_hash["Reason Type"],
			  opposite_party: row_hash["Opposite Party"],
			  linked_transaction_id: row_hash["Linked Transaction ID"]
			)
		when "Channel Three"
			import_channel_three(spreadsheet,header)
		when "Channel Four"
			import_channel_four(spreadsheet,header)
		when "Channel Five"
			import_channel_five(spreadsheet,header)
		when "Channel Six"
			import_channel_six(spreadsheet,header)
		else
			Rails.logger.warn("Unknown model: #{model_name}")
		end
		Rails.logger.warn "Imported Successfully"
	end

	# def import_channel_one(sheet, header) 
	# 	(2..sheet.last_row).each do |i|
	# 		row = Hash[[header, sheet.row(i)].transpose]

	# 		ChannelOne.create!(
	# 		  transaction_id: row["Transaction ID"],
	# 		  sender_msisdn: row["Sender Msisdn"],
	# 		  transaction_amount: row["Transaction Amount"],
	# 		  transaction_datetime: row["Transaction Date and Time"],
	# 		  transaction_type: row["Transaction Type"],
	# 		  receiver_msisdn: row["Receiver Msisdn"],
	# 		  service_name: row["Service Name"],
	# 		  transaction_status: row["Transaction Status"],
	# 		  reference_number: row["Reference Number"],
	# 		  previous_balance: row["Previous Balance"],
	# 		  post_balance: row["Post Balance"],
	# 		  external_transaction_id: row["external_transaction_id"]
	# 		)
	# 	end
	# 	Rails.logger.warn "Imported Successfully"
	# end

	# def import_channel_two(sheet,header)
	# 	(2..sheet.last_row).each do |i|
	# 		row = Hash[[header, sheet.row(i)].transpose]

	# 		ChannelTwo.create!(
	# 		  receipt_no: row["Receipt No."],
	# 		  completion_time: row["Completion Time"],
	# 		  initiation_time: row["Initiation Time"],
	# 		  details: row["Details"],
	# 		  transaction_status: row["Transaction Status"],
	# 		  currency: row["Currency"],
	# 		  paid_in: row["Paid In"],
	# 		  withdrawn: row["Withdrawn"],
	# 		  balance: row["Balance"],
	# 		  reason_type: row["Reason Type"],
	# 		  opposite_party: row["Opposite Party"],
	# 		  linked_transaction_id: row["Linked Transaction ID"]
	# 		)
	# 	end
	# 	Rails.logger.warn "Imported Successfully"
	# end

	# def import_channel_six(sheet,header)
	# 	(2..sheet.last_row).each do |i|
	# 		row = Hash[[header, sheet.row(i)].transpose]

	# 		ChannelThree.create!(
	# 		  transfer_id: row["Transfer_ID"],
	# 		  reference_number: row["Refer_Number"],
	# 		  transfer_date: row["Trans_Date"],
	# 		  previous_balance: row["Prev Balance"],
	# 		  post_balance: row["Post Bal"],
	# 		  amount: row["Amount"],
	# 		  transfer_status: row["Transfer_Status"],
	# 		  money_payer_receiver: row["MoneyPayer/Receiver"],
	# 		  account: row["Account"],
	# 		  status_change_date: row["Status_Change_date"]
	# 		)
	# 	end
	# 	Rails.logger.warn "Imported Successfully"
	# end
end