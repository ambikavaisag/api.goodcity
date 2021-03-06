module Api
  module V1
    class MessagesController < Api::V1::ApiController
      load_and_authorize_resource :message, parent: false

      resource_description do
        short "List, show, create and mark_read a message."
        formats ["json"]
        error 401, "Unauthorized"
        error 404, "Not Found"
        error 422, "Validation Error"
        error 500, "Internal Server Error"
      end

      def_param_group :message do
        param :message, Hash, require: true do
          param :body, String, desc: "Message body", allow_nil: true
          param :sender, String, desc: "Message sent by"
          param :is_private, [true, false], desc: "Message Type e.g. [public, private]"
          param :offer_id, String, desc: "Offer for which message has been posted", allow_nil: true
          param :item_id, String, desc: "Item for which message has been posted", allow_nil: true
          param :state, String, desc: "Current User's Subscription State e.g. unread, read "
          param :order_id, String, desc: "Order id on which message is created", allow_nil: true
        end
      end

      api :GET, "/v1/messages", "List all messages"
      param :ids, Array, of: Integer, desc: "Filter by message ids e.g. ids = [1,2,3,4]"
      param :offer_id, String, desc: "Return messages for offer id."
      param :item_id, String, desc: "Return messages for item id."
      param :order_id, String, desc: "Return messages for order id"
      param :state, String, desc: "Message state (unread|read) to filter on"
      def index
        @messages = @messages.where(id: params[:ids].split(",")) if params[:ids].present?
        @messages = @messages.where(offer_id: params[:offer_id].split(",")) if params[:offer_id].present?
        @messages = @messages.where(order_id: params[:order_id].split(",")) if params[:order_id].present?
        @messages = @messages.where(item_id: params[:item_id].split(",")) if params[:item_id].present?
        @messages = @messages.with_state_for_user(User.current_user, params[:state]) if params[:state].present?
        render json: @messages, each_serializer: serializer
      end

      api :GET, "/v1/messages/1", "Get a message"
      def show
        render json: @message, serializer: serializer
      end

      api :POST, "/v1/messages", "Create an message"
      param_group :message
      def create
        @message.order_id = order_id
        @message.sender_id = current_user.id
        save_and_render_object(@message)
      end

      api :PUT, "/v1/messages/:id/mark_read", "Mark message as read"
      def mark_read
        @message.mark_read!(current_user.id, app_name)
        render json: @message, serializer: serializer
      end

      private

      def order_id
        params[:message][:designation_id].presence || params[:message][:order_id].presence
      end

      def serializer
        Api::V1::MessageSerializer
      end

      def message_params
        params.require(:message).permit(
          :body, :is_private,
          :offer_id, :item_id, :order_id
        )
      end
    end
  end
end
