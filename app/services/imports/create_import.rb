module Imports
	class CreateImport
		class ValidationError < StandardError; end


		def initialize(model_name:, user:, file: nil, data_array: nil, transaction_category: nil)
			@model_name = model_name
			@user = user
			@file = file
			@data_array = data_array
			@transaction_category = transaction_category
		end

		def call
			if file.present?
				handle_file_upload
			elsif data_array.present?
				handle_json_payload
			else
				raise ValidationError, "Please provide a file upload or JSON data"
			end
		end


		private

		attr_reader :model_name, :user, :file, :data_array

		# --- Handle File Upload ---
		def handle_file_upload
			filename = file.original_filename
			folder = Rails.root.join(
				"public", 
				"storage", 
				Time.current.strftime("%Y"), 
				Time.current.strftime("%b"),
				Time.current.strftime("%d"), 
				model_name.parameterize
			)
			FileUtils.mkdir_p(folder)

			file_path = folder.join(filename)
			File.open(file_path, "wb") { |f| f.write(file.read) }

			# Detect extension and tell Roo explicitly
			ext = File.extname(file_path.to_s).delete('.').downcase

			spreadsheet = Roo::Spreadsheet.open(file_path.to_s, extension: ext.presence || :xlsx)
			
			header = spreadsheet.row(6).map(&:to_s).map(&:strip)

			validate_header!(header)

			total_rows = [spreadsheet.last_row - 6, 0].max

			relative_path = file_path.to_s.sub(Rails.root.join("public").to_s + "/", "")

			import_file = ImportFile.create!(
				user: user,
				channel_name: model_name,
				file_path: relative_path,
				status: :pending,
				total_rows: total_rows,
				processed_count: 0,
				rejected_count: 0
			)

			job_id = ImportWorker.perform_async(file_path.to_s, model_name, import_file.id, nil,  @transaction_category)
			import_file.update!(job_id: job_id)

			import_file
		end

		# --- Handle JSON Payload ---
		def handle_json_payload
			unless data_array.is_a?(Array) && data_array.any?
        raise ValidationError, "Expecting JSON array in 'data' param"
      end

      header = data_array.first.keys.map(&:to_s).map(&:strip)
      validate_header!(header)


      import_file = ImportFile.create!(
        user: user,
        channel_name: model_name,
        file_path: nil,
        status: :pending,
        total_rows: data_array.length,
        processed_count: 0,
        rejected_count: 0
      )

      job_id = ImportWorker.perform_async(nil, model_name, import_file.id, data_array.to_json, @transaction_category)
      import_file.update!(job_id: job_id)

      import_file
		end

		# --- Shared Validation ---
		def validate_header!(header)
			validator = FileValidator.new(model_name, header)
			raise ValidationError, validator.error_message unless validator.valid?
		end
	end
end