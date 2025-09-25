class RecordsController < ApplicationController
  before_action :set_channel_model
  before_action :load_files, only: [:index]

  FILTER_FIELDS = {
    "ChannelOne" => %i[transaction_id reference_number status transaction_amount start_date end_date file_id],
    "ChannelTwo" => %i[receipt_no reference_number status transaction_amount start_date end_date file_id],
    "ChannelThree" => %i[transfer_id reference_number status transaction_amount start_date end_date file_id],
    "ChannelFour" => %i[transaction_id reference_number status transaction_amount start_date end_date file_id],
    "ChannelFive" => %i[receipt_no reference_number status transaction_amount start_date end_date file_id],
    "ChannelSix" => %i[transfer_id reference_number status transaction_amount start_date end_date file_id]
  }

  AMOUNT_COLUMN = {
    "ChannelOne"   => :transaction_amount,
    "ChannelThree" => :amount,
    "ChannelSix"   => :amount
  }.freeze
  
  def index
    # Start with all channel records
    @records = @channel_model.all

    # Apply filters dynamically
    @records = apply_filters(@records)

    # Include associations
    @records = @records.includes(import_file: :user)
                       .order(created_at: :desc)
                       .page(params[:page])
                       .per(15)
  end

  private

  def set_channel_model
    channel = params[:channel].presence || "ChannelOne"
    @channel_model = channel.constantize
    @channel_name  = channel
  end

  def load_files
    channel_name = @channel_name.gsub(/([A-Z])/, ' \1').strip
    @files = ImportFile.where(channel_name: channel_name).order(created_at: :desc)
  end

  def apply_filters(records)
    fields = FILTER_FIELDS[@channel_name] || []

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
        column = AMOUNT_COLUMN[@channel_name] || :transaction_amount
        records = records.order(column => sort_order)

      when :start_date
        if params[:end_date].present?
          date_field = @channel_name == "ChannelTwo" ? :initiated_at : :transaction_datetime
          records = records.where(date_field => value.to_date.beginning_of_day..params[:end_date].to_date.end_of_day)
        end
      when :file_id
        records = records.where(import_file_id: value)
      end
    end

    records
  end
end
