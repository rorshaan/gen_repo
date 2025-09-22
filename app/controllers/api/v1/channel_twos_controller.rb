class Api::V1::ChannelTwosController < ApplicationController
	respond_to :json
	skip_before_action :verify_authenticity_token

	def index
		channel_twos = ImportFile.includes(:channel_twos, :user)
                              .where.not(channel_twos: { id: nil })
                              .order(created_at: :desc)

    render json: channel_twos.as_json                    
	end
end