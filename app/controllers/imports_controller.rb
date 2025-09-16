class ImportsController < ApplicationController
	protect_from_forgery unless: -> { request.format.json? }

	def new
	end

	def create
		model_name = params[:model].to_s

		# file upload multipart/form-data (HTML or API client)
		if params[:file].present?
			uploaded = params[:file]
			filename = uploaded.original_filename

			folder = Rails.root.join(
				"public",
				"storage",
				Time.current.strftime("%Y"),
        Time.current.strftime("%b"),
        model_name.parameterize
			)
			FileUtils.mkdir_p(folder)

			file_path = folder.join(filename)
			File.open(file_path, "wb") { |f| f.write(uploaded.read) }
			
			spreadsheet = Roo::Spreadsheet.open(file_path.to_s)
			header = spreadsheet.row(1).map(&:to_s).map(&:strip)
			validator = FileValidator.new(model_name, header)

			unless validator.valid?
				return respond_with_error(422, validator.error_message)
			end

			total_rows = [spreadsheet.last_row - 1, 0].max
			# Track upload
			relative_path = file_path.to_s.sub(Rails.root.join("public").to_s + "/", "")

			import_file = ImportFile.create!(
				user: current_user&.id || User.find_by(id: params[:user_id]),
				channel_name: model_name,
				file_path: relative_path,
				status: :pending,
				total_rows: total_rows,
				processed_count: 0,
				rejected_count: 0
			)

			job_id = ImportWorker.perform_async(file_path.to_s, model_name, nil, import_file.id)
			import_file.update!(job_id: job_id)

			return respond_with_success(job_id, model_name)
		end


		# JSON payload (raw data)
		if request.format.json? || params[:data].present?
			# params[:data] expected to be array of hashes (already parsed)
      data_array = params[:data] || (request.body.present? ? (JSON.parse(request.body.read) rescue nil) : nil)

      unless data_array.is_a?(Array) && data_array.any?
        return respond_with_error(422, "Expecting JSON array in 'data' param")
      end

      header = data_array.first.keys.map(&:to_s).map(&:strip)
      validator = FileValidator.new(model_name, header)

      unless validator.valid?
        return respond_with_error(422, validator.error_message)
      end

      # Track upload
      import_file = ImportFile.create!(
        user: current_user || User.find_by(id: params[:user_id]),
        channel_name: model_name,
        file_path: nil,
        status: :pending,
        total_rows: data_array.length,
				processed_count: 0,
				rejected_count: 0
      )

      # enqueue worker with JSON string (Sidekiq arguments must be JSON serializable)
      job_id = ImportWorker.perform_async(nil, model_name, data_array.to_json)
      import_file.update!(job_id: job_id)

      return respond_with_success(job_id, model_name)
		end

		# neither file nor JSON provided
    respond_with_error(400, "Please provide a file upload or JSON data")
	end

	private

	def respond_with_success(job_id, model_name)
		message = "#{model_name} import started"
		respond_to do |format|
			format.html { redirect_to import_files_path, notice: "#{message}! You’ll be notified when it finishes." }
      format.json { render json: { message: message, job_id: job_id }, status: :accepted }
		end
	end


	def respond_with_error(status, message)
		respond_to do |format|
			format.html { redirect_to new_import_path, alert: message}
			format.json { render json: { error: message }, status: status }
		end
	end
end