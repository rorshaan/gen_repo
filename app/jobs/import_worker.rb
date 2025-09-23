class ImportWorker
	include Sidekiq::Worker


	def perform(file_path, model_name, json_data = nil, import_file_id)
		import_file = ImportFile.find(import_file_id)
		import_file.processing!

		model_name = model_name.to_s
		inserted = 0
		rejected_rows = []

		if json_data.present?
			data_array = JSON.parse(json_data) rescue []
			inserted, rejected_rows = import_from_json(data_array, model_name, import_file)
		elsif file_path.present?
			inserted, rejected_rows = import_from_spreadsheet(file_path, model_name, import_file)
		else
			Rails.logger.warn("[ImportWorker] no file or json data provided for #{model_name}")
		end

		#update counts
		import_file.update!(
			processed_count: (import_file.processed_count || 0) + inserted,
			rejected_count: rejected_rows.size
		)

		# write rejected CSV (if any) and save relative path
		if rejected_rows.any?
			relative = write_rejected_csv(import_file, model_name, rejected_rows)
			import_file.update!(error_file_path: relative)
		end

		import_file.completed!
	rescue => e
		import_file.failed!
		Rails.logger.error("[ImportWorker] Error importing #{model_name}: #{e.class}: #{e.message}\n#{e.backtrace.first(10).join("\n")}")
	end

	private


	def import_from_spreadsheet(file_path, model_name, import_file)
		spreadsheet = Roo::Spreadsheet.open(file_path)
		header = spreadsheet.row(1).map(&:to_s).map(&:strip)

		validator = FileValidator.new(model_name, header)
		unless validator.valid?
      Rails.logger.warn("[ImportWorker] Invalid headers for #{model_name}: #{validator.error_message}")
      return [0, [{ row_number: nil, raw: {}, error: validator.error_message }]]
    end

    import_file.update!(total_rows: [spreadsheet.last_row - 1, 0].max) if import_file && import_file.total_rows.blank?

    inserted = 0
    rejected = []

    (2..spreadsheet.last_row).each do |i|
			row_hash = Hash[[header, spreadsheet.row(i)].transpose]
			begin
				ok = create_record_for(model_name, row_hash, import_file)
				if ok
					inserted += 1
				else
					rejected << { row_number: i, raw: row_hash, error: "Duplicate (exists in DB or blank unique key)" }
				end
			rescue => e
				rejected << { row_number: i, raw: row_hash, error: e.message }
			end
		end

		[inserted, rejected]
	end

	def import_from_json(data_array, model_name, import_file)
		unless data_array.is_a?(Array) && data_array.any?
			Rails.logger.warn("[ImportWorker] No JSON data to import for #{model_name}")
      return
		end

		header = data_array.first.keys.map(&:to_s).map(&:strip)
		validator = FileValidator.new(model_name, header)
		unless validator.valid?
      Rails.logger.warn("[ImportWorker] Invalid JSON keys for #{model_name}: #{validator.error_message}")
      return [0, [{ row_number: nil, raw: {}, error: validator.error_message }]]
    end

    import_file.update!(total_rows: data_array.length) if import_file && import_file.total_rows.blank?

    inserted = 0
    rejected = []

    data_array.each_with_index do |row, idx|
    	row_hash = row.transform_keys(&:to_s)
    	begin
    	ok = create_record_for(model_name, row_hash, import_file)
    	if ok
    		inserted += 1
    	else
    		 rejected << { row_number: idx + 1, raw: row_hash, error: "Duplicate (exists in DB or blank unique key)" }
    	end
    	rescue => e
    		rejected << { row_number: idx + 1, raw: row_hash, error: e.message }
    	end
    end

    [inserted, rejected]
	end

	def create_record_for(model_name, row_hash, import_file)
		case model_name
		when "Channel One"
			unique_value = row_hash["Transaction ID"].to_s.strip
			return false if unique_value.blank? || ChannelOne.exists?(transaction_id: unique_value)

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
			  external_transaction_id: row_hash["external_transaction_id"],
			  import_file_id: import_file.id
			)
		when "Channel Two"
			unique_value = row_hash["Receipt No."].to_s.strip
			return false if unique_value.blank? || ChannelTwo.exists?(receipt_no: unique_value)

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
			  linked_transaction_id: row_hash["Linked Transaction ID"],
			  import_file_id: import_file.id
			)
		when "Channel Three"
			unique_value = row_hash["Transfer_ID"].to_s.strip
      return false if unique_value.blank? || ChannelThree.exists?(transfer_id: unique_value)

      ChannelThree.create!(
			  transfer_id: row["Transfer_ID"],
			  reference_number: row["Refer_Number"],
			  transfer_date: row["Trans_Date"],
			  previous_balance: row["Prev Balance"],
			  post_balance: row["Post Bal"],
			  amount: row["Amount"],
			  transfer_status: row["Transfer_Status"],
			  money_payer_receiver: row["MoneyPayer/Receiver"],
			  account: row["Account"],
			  status_change_date: row["Status_Change_date"],
			  import_file_id: import_file.id
			)
		when "Channel Four"
			import_channel_four(spreadsheet,header)
		when "Channel Five"
			import_channel_five(spreadsheet,header)
		when "Channel Six"
			import_channel_six(spreadsheet,header)
		else
			Rails.logger.warn("Unknown model: #{model_name}")
			false
		end
		Rails.logger.warn "Imported Successfully"
	end

	# Write rejected rows to CSV and return relative path under public/ (no leading slash)
	def write_rejected_csv(import_file, channel_name, rejected_rows)
		folder = Rails.root.join("public", "storage", "rejected", Time.current.strftime("%Y"), Time.current.strftime("%b"), Time.current.strftime("%d"), channel_name.parameterize)
		FileUtils.mkdir_p(folder)

		filename = "rejected_#{import_file.id}_#{Time.current.to_i}.csv"
		abs_path = folder.join(filename)

		require 'csv'

		CSV.open(abs_path, "wb:utf-8") do |csv|
			sample_raw = rejected_rows.map { |r| r[:raw] }.find(&:present?) || {}
			base_headers = sample_raw.respond_to?(:keys) ? sample_raw.keys.map(&:to_s) : []

			csv << (base_headers + ["error"])
			rejected_rows.each do |r|
				raw = r[:raw] || {}
				row_values = base_headers.map { |h| raw[h] || raw[h.to_sym] || "" }
				csv << (row_values + [r[:error]])
			end

		# return relative path (no leading slash)
    abs_path.to_s.sub(Rails.root.join("public").to_s + "/", "")
		end
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