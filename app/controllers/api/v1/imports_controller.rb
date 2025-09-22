class Api::V1::ImportsController < ApplicationController
	respond_to :json
	skip_before_action :verify_authenticity_token

	def create
		begin
			import_file = Imports::CreateImport.new(
				model_name: params[:model].to_s,
				user: current_user || User.find_by(id: params[:user_id]),
				file: params[:file],
				data_array: extract_json_data
			).call

			render json: { 
				message: "#{import_file.channel_name} import started", 
				job_id: import_file.job_id 
			}, status: :accepted

		rescue Imports::CreateImport::ValidationError => e
			render json: { error: e.message }, status: :unprocessable_entity
		end
	end

	private

	def extract_json_data
    return nil if params[:file].present? # don’t parse JSON if it’s a file upload
    return params[:data] if params[:data].present?

    request.body.present? ? JSON.parse(request.body.read) : nil
  end

end