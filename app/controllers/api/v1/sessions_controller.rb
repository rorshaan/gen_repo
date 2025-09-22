module Api
  module V1
    class SessionsController < Devise::SessionsController
      respond_to :json
      skip_before_action :verify_authenticity_token

      def create
        user = User.find_for_database_authentication(email: params[:user][:email])
        if user && user.valid_password?(params[:user][:password])
          sign_in(user)
          render json: {
            message: 'Logged in successfully',
            user: { id: user.id, email: user.email }
          }, status: :ok
        else
          render json: { error: 'Invalid Email or Password' }, status: :unauthorized
        end
      end

      def destroy
        sign_out(current_user)
        render json: { message: 'Logged out successfully' }, status: :ok
      end

      private

      # def respond_with(resource, _opts = {})
      #   render json: {
      #     message: 'Logged in successfully',
      #     user: { id: resource.id, email: resource.email }
      #   }, status: :ok
      # end

      # def respond_to_on_destroy
      #   render json: { message: 'Logged out successfully' }, status: :ok
      # end
    end
  end
end
