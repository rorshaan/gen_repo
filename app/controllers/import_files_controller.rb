class ImportFilesController < ApplicationController
  def index
    @import_files = ImportFile.includes(:user).order(created_at: :desc).page(params[:page]).per(20)
  end

  def show
    @import_file = ImportFile.find(params[:id])
  end

  def download
    import_file = ImportFile.find(params[:id])
    absolute_path = Rails.root.join("public", import_file.file_path)

    if File.exist?(absolute_path)
      send_file absolute_path, filename: File.basename(absolute_path), type: "application/octet-stream", disposition: "attachment"
    else
      redirect_to import_files_path, alert: "File not found"
    end
  end
end
