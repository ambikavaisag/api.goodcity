module Api
  module V1
    class CancellationReasonsController < Api::V1::ApiController
      load_and_authorize_resource :cancellation_reason, parent: false

      def index
        if params["ids"].present?
          @cancellation_reasons = @cancellation_reasons.where(id: params["ids"].split(",").flatten)
        else
          @cancellation_reasons = @cancellation_reasons.visible
        end
        render json: @cancellation_reasons, each_serializer: serializer
      end

      def show
        render json: @cancellation_reason, serializer: serializer
      end

      private

      def serializer
        Api::V1::CancellationReasonSerializer
      end
    end
  end
end
