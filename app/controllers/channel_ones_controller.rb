class ChannelOnesController < ApplicationController
	def index
		@channel_ones = ChannelOne.all.order(created_at: :desc).page(params[:page]).per(10)
	end
end