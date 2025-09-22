class Api::V1::ImportFilesController < ApplicationController
	respond_to :json
	skip_before_action :verify_authenticity_token

	def index
		import_files = ImportFile.includes(:user).order(created_at: :desc).page(params[:page]).per(20)
		render json: import_files.as_json(only: [:id, :file_path, :created_at],
                                          include: { user: { only: [:id, :email] } })
	end

	def show
    import_file = ImportFile.find(params[:id])
    render json: import_file.as_json(only: [:id, :file_path, :created_at],
                                     include: { user: { only: [:id, :email] } })
  end

  def download
    import_file = ImportFile.find(params[:id])
    absolute_path = Rails.root.join("public", import_file.file_path)

    if File.exist?(absolute_path)
      send_file absolute_path, filename: File.basename(absolute_path), type: "application/octet-stream", disposition: "attachment"
    else
      render json: { error: "File not found" }, status: :not_found
    end
  end

  def download_rejected
    import_file = ImportFile.find(params[:id])
    absolute_path = import_file.absolute_error_file_path

    if absolute_path && File.exist?(absolute_path)
      send_file absolute_path, filename: File.basename(absolute_path), type: "text/csv", disposition: "attachment"
    else
      render json: { error: "Rejected CSV not found" }, status: :not_found
    end
  end
  
end