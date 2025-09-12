class ChannelTwosController < ApplicationController
	def index
		@import_files = ImportFile.includes(:channel_twos, :user)
                              .where.not(channel_twos: { id: nil })
                              .order(created_at: :desc)
                              .page(params[:page])
                              .per(10)
	end
end