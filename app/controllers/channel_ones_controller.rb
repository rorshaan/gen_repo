class ChannelOnesController < ApplicationController
	def index
		@import_files = ImportFile.includes(:channel_ones, :user)
                              .where.not(channel_ones: { id: nil })
                              .order(created_at: :desc)
                              .page(params[:page])
                              .per(10)
	end
end