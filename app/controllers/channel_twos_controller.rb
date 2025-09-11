class ChannelTwosController < ApplicationController
	def index
		@channel_twos = ChannelTwo.all.order(created_at: :desc).page(params[:page]).per(10)
	end
end