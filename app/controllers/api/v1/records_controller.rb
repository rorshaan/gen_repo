class Api::V1::RecordsController < ApplicationController

  def index
    records = ChannelTransaction.all
    
    records = records.where(type: params[:channel]) if params[:channel].present?

    records = records.includes(import_file: :user)
                     .order(created_at: :desc)
                     .page(params[:page])
                     .per(15)

    render json: {
      total_count: records.total_count,
      records: records.as_json(
        include: { import_file: { only: [:id, :file_name], include: { user: { only: [:id, :name, :email] } } } }
      )
    }
  end
end
