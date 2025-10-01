class ImportsController < ApplicationController
	protect_from_forgery unless: -> { request.format.json? }

	def new
	end

	def create
		import_file = Imports::CreateImport.new(
			model_name: params[:model].to_s,
			user: current_user,
			file: params[:file],
			transaction_category: params[:transaction_category]
		).call

		redirect_to import_files_path, notice: "#{import_file&.channel_name} import started ! You’ll be notified when it finishes."
	rescue Imports::CreateImport::ValidationError => e
		redirect_to new_import_path, alert: e.message
	end
end