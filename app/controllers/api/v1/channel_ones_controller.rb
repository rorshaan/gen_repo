class Api::V1::ChannelOnesController < ApplicationController
	respond_to :json
	skip_before_action :verify_authenticity_token

	def index
		channel_ones = ImportFile.includes(:channel_ones, :user)
                              .where.not(channel_ones: { id: nil })
                              .order(created_at: :desc)

    render json: channel_ones.as_json                       
	end
end