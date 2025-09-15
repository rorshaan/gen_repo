class StorageController < ApplicationController
  def index
    files = ImportFile.order(created_at: :desc).includes(:user)
    @tree = build_tree(files)
  end

  # This action returns the partial that will be loaded into the turbo frame.
  def show
    @selected_file = ImportFile.find(params[:id])
    channel = params[:channel].to_s

    @records =
      case channel
      when "Channel One"
        @selected_file.channel_ones.order(:id).page(params[:page]).per(20)
      when "Channel Two"
        @selected_file.channel_twos.order(:id).page(params[:page]).per(20)
      else
        []
      end

    # render partial only (will be inserted into the turbo-frame)
    render partial: "storage/transactions", locals: { file: @selected_file, records: @records }
  end

  private

  def build_tree(files)
    tree = {}

    files.each do |f|
      y = f.created_at.strftime("%Y")
      m = f.created_at.strftime("%b")
      d = f.created_at.strftime("%d/%b/%y")
      channel = f.channel_name.presence || "Unknown"

      tree[y] ||= {}
      tree[y][m] ||= {}
      tree[y][m][d] ||= {}
      tree[y][m][d][channel] ||= []

      tree[y][m][d][channel] << {
        id: f.id,
        name: File.basename(f.file_path.to_s),
        # view_url loads transactions into turbo frame (no download)
        view_url: storage_path(f.id, channel: channel),
        # download_url points to the actual file under public/ (served directly)
        download_url: f.file_path.present? ? "/#{f.file_path}" : nil,
        rows: f.total_rows,
        status: f.status
      }
    end

    # optional: sort years descending
    tree.sort_by { |year, _| -year.to_i }.to_h
  end
end
