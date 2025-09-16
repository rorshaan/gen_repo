class StorageController < ApplicationController
  def index
    files = ImportFile.order(created_at: :desc).includes(:user)
    @tree = build_tree(files)
  end

  def show
    @selected_file = ImportFile.find(params[:id])
    channel = params[:channel].to_s
    files = [@selected_file]

    @records =
      case channel
      when "Channel One"
        rel = ChannelOne.where(import_file_id: files.map(&:id))
        rel = rel.where("transaction_id LIKE ?", "%#{params[:transaction_id].strip}%") if params[:transaction_id].present?
        rel = rel.where("reference_number LIKE ?", "%#{params[:reference_number].strip}%") if params[:reference_number].present?
        # rel = rel.where(transaction_status: params[:status]) if params[:status].present? && params[:status] != "All"
        if params[:status].present?
          case params[:status]
          when "Success"
            rel = rel.where("transaction_status ILIKE ?", "%Success%")
          when "Failed"
            rel = rel.where("transaction_status ILIKE ?", "%Failed%")
          end
        end
        rel = rel.where(import_file_id: params[:file_id]) if params[:file_id].present?
        if params[:start_date].present? && params[:end_date].present?
          rel = rel.where(transaction_datetime: params[:start_date].to_date.beginning_of_day..params[:end_date].to_date.end_of_day)
        end

        if params[:transaction_amount].present?
          sort_order = params[:transaction_amount] == "Descending" ? :desc : :asc
          rel = rel.order(transaction_amount: sort_order)
        end

        # rel = rel.order(transaction_amount: (params[:sort] == "desc" ? :desc : :asc)) if params[:sort].present?
        rel.page(params[:page]).per(20)
      when "Channel Two"
        rel = ChannelTwo.where(import_file_id: files.map(&:id))
        rel = rel.where("receipt_no LIKE ?", "%#{params[:transaction_id]}%") if params[:transaction_id].present?
        rel = rel.where("reference_number LIKE ?", "%#{params[:reference_number]}%") if params[:reference_number].present?
        if params[:status].present?
          case params[:status]
          when "Success"
            rel = rel.where("transaction_status ILIKE ?", "%Success%")
          when "Failed"
            rel = rel.where("transaction_status ILIKE ?", "%Failed%")
          end
        end
        if params[:start_date].present? && params[:end_date].present?
          rel = rel.where(initiated_at: params[:start_date].to_date.beginning_of_day..params[:end_date].to_date.end_of_day)
        end
        if params[:transaction_amount].present?
          sort_order = params[:transaction_amount] == "Descending" ? :desc : :asc
          rel = rel.order(transaction_amount: sort_order)
        end
        rel.page(params[:page]).per(20)
      else
        ChannelOne.none.page(params[:page]).per(20)
      end

    # render partial only (will be inserted into the turbo-frame)
    render partial: "storage/transactions", locals: { file: @selected_file, channel: channel, records: @records, files: files }
  end

  def show_model
    channel = params[:model_name].to_s

    # collect all files for this channel
    files = ImportFile.where(channel_name: channel)
# byebug
    # Filter files by upload date if provided
    if params[:file_date].present?
      date = params[:file_date].to_date
      files = files.where(created_at: date.beginning_of_day..date.end_of_day)
    end

    # merge all records across files
    @records =
      case channel
      when "Channel One"
        rel = ChannelOne.where(import_file_id: files.ids)
        rel = rel.where("transaction_id LIKE ?", "%#{params[:transaction_id].strip}%") if params[:transaction_id].present?
        rel = rel.where("reference_number LIKE ?", "%#{params[:reference_number].strip}%") if params[:reference_number].present?
        if params[:status].present?
          case params[:status]
          when "Success"
            rel = rel.where("transaction_status ILIKE ?", "%Success%")
          when "Failed"
            rel = rel.where("transaction_status ILIKE ?", "%Failed%")
          end
        end
        rel = rel.where(import_file_id: params[:file_id]) if params[:file_id].present?
        if params[:start_date].present? && params[:end_date].present?
          rel = rel.where(transaction_datetime: params[:start_date].to_date.beginning_of_day..params[:end_date].to_date.end_of_day)
        end
        if params[:transaction_amount].present?
          sort_order = params[:transaction_amount] == "Descending" ? :desc : :asc
          rel = rel.order(transaction_amount: sort_order)
        end
        rel.page(params[:page]).per(20)
      when "Channel Two"
        rel = ChannelTwo.where(import_file_id: files.ids)
        rel = rel.where("receipt_no LIKE ?", "%#{params[:transaction_id].strip}%") if params[:transaction_id].present?
        rel = rel.where("reference_number LIKE ?", "%#{params[:reference_number].strip}%") if params[:reference_number].present?
        if params[:status].present?
          case params[:status]
          when "Success"
            rel = rel.where("transaction_status ILIKE ?", "%Success%")
          when "Failed"
            rel = rel.where("transaction_status ILIKE ?", "%Failed%")
          end
        end
        rel = rel.where(import_file_id: params[:file_id]) if params[:file_id].present?
        if params[:start_date].present? && params[:end_date].present?
          rel = rel.where(initiated_at: params[:start_date].to_date.beginning_of_day..params[:end_date].to_date.end_of_day)
        end
        if params[:transaction_amount].present?
          sort_order = params[:transaction_amount] == "Descending" ? :desc : :asc
          rel = rel.order(transaction_amount: sort_order)
        end
        rel.page(params[:page]).per(20)
      else
        ChannelOne.none.page(params[:page]).per(20)
      end

    # Determine selected file from dropdown
    @selected_file = ImportFile.find_by(id: params[:file_id]) if params[:file_id].present?

    # render same transactions partial, but without a single file
    render partial: "storage/transactions", locals: { file: @selected_file, channel: channel, records: @records, files: files }
  end


  private

  def build_tree(files)
    tree = {}

    files.each do |f|
      y = f.created_at.strftime("%Y")
      m = f.created_at.strftime("%b")
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
end
