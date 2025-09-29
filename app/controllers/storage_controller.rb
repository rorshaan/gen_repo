class StorageController < ApplicationController

  FILTER_FIELDS = {
    "Channel One"   => %i[transaction_id reference_number status transaction_amount start_date end_date file_id],
    "Channel Two"   => %i[receipt_no reference_number status transaction_amount start_date end_date file_id],
    "Channel Three" => %i[transfer_id reference_number status transaction_amount start_date end_date file_id],
    "Channel Four"  => %i[transaction_id reference_number status transaction_amount start_date end_date file_id],
    "Channel Five"  => %i[receipt_no reference_number status transaction_amount start_date end_date file_id],
    "Channel Six"   => %i[transfer_id reference_number status transaction_amount start_date end_date file_id]
  }.freeze

  AMOUNT_COLUMN = {
    "Channel One"   => :transaction_amount,
    "Channel Three" => :amount,
    "Channel Six"   => :amount
  }.freeze

  def index
    files = ImportFile.where.not(processed_count: 0).order(created_at: :desc).includes(:user)
    @tree = build_tree(files)
  end

  def show_model
    channel = params[:model_name].to_s
    files = ImportFile.where(channel_name: channel)
    files = files.where(created_at: params[:file_date].to_date.all_day) if params[:file_date].present?

    # Get all records for the channel and filter
    @records = channel_class(channel).where(import_file_id: files.ids)
    @records = filter_records(@records, channel)
    @records = @records.includes(:import_file).page(params[:page]).per(20)

    @selected_file = ImportFile.find_by(id: params[:file_id]) if params[:file_id].present?

    render partial: "storage/transactions", locals: { file: @selected_file, channel: channel, records: @records, files: files }
  end

  private

  def channel_class(channel)
    channel.delete(' ').constantize
  end

  def build_tree(files)
    tree = {}

    files.each do |f|
      y = f.created_at.strftime("%Y")
      m = f.created_at.strftime("%B")
      d = f.created_at.strftime("%d/%b/%Y")
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

  def filter_records(records, channel)
    fields = FILTER_FIELDS[channel] || []

    fields.each do |field|
      value = params[field]
      next if value.blank?

      case field
      when :transaction_id, :receipt_no, :reference_number, :transfer_id
        records = records.where("#{field} LIKE ?", "%#{value.strip}%")
      when :status
        records = records.where("transaction_status ILIKE ?", "%#{value}%") if value != "All"
      when :transaction_amount, :amount
        sort_order = value == "Descending" ? :desc : :asc
        column = AMOUNT_COLUMN[channel] || :transaction_amount
        records = records.order(column => sort_order)
      when :start_date
        if params[:end_date].present?
          date_field = channel == "Channel Two" || channel == "Channel Five" ? :initiated_at : :transaction_datetime
          records = records.where(date_field => value.to_date.beginning_of_day..params[:end_date].to_date.end_of_day)
        end
      when :file_id
        records = records.where(import_file_id: value)
      end
    end

    records
  end
end
