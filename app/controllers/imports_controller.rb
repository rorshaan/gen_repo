class ImportsController < ApplicationController
	protect_from_forgery unless: -> { request.format.json? }

	def new
	end

	def create
		model_name = params[:model].to_s

		# file upload multipart/form-data (HTML or API client)
		if params[:file].present?
			uploaded = params[:file]
			tmp_filename = "#{SecureRandom.uuid}#{File.extname(uploaded.original_filename)}"
			file_path = Rails.root.join("tmp", tmp_filename)
			File.open(file_path, "wb") { |f| f.write(uploaded.read) }
			
			spreadsheet = Roo::Spreadsheet.open(file_path.to_s)
			header = spreadsheet.row(1).map(&:to_s).map(&:strip)
			validator = FileValidator.new(model_name, header)

			unless validator.valid?
				File.delete(file_path) if File.exist?(file_path)
				return respond_with_error(422, validator.error_message)
			end

			job_id = ImportWorker.perform_async(file_path.to_s, model_name, nil)
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

      # enqueue worker with JSON string (Sidekiq arguments must be JSON serializable)
      job_id = ImportWorker.perform_async(nil, model_name, data_array.to_json)
      return respond_with_success(job_id, model_name)
		end

		# neither file nor JSON provided
    respond_with_error(400, "Please provide a file upload or JSON data")
	end

	private

	def respond_with_success(job_id, model_name)
		message = "#{model_name} import started"
		respond_to do |format|
			format.html { redirect_to root_path, notice: "#{message}! You’ll be notified when it finishes." }
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