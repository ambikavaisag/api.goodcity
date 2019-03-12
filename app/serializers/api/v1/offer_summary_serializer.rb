module Api::V1
  class OfferSummarySerializer < ApplicationSerializer
    embed :ids, include: true

    attributes :id, :state, :created_at, :inactive_at,
      :updated_at, :submitted_at, :reviewed_at, :review_completed_at,
      :received_at, :cancelled_at, :start_receiving_at

    has_one  :closed_by, serializer: UserSummarySerializer, root: :user
    has_one  :created_by, serializer: UserSummarySerializer, root: :user
    has_one  :reviewed_by, serializer: UserSummarySerializer, root: :user
    has_one  :received_by, serializer: UserSummarySerializer, root: :user
    has_one  :display_image, serializer: ImageSerializer, root: :images
    has_one  :delivery, serializer: DeliverySerializer, root: :delivery

    def display_image
      object.images.first
    end

    # For Admin app offer summary, only show 
    # deliveries and schedules for actively scheduled offers
    def include_delivery?
      object.state.include?('scheduled')
    end

  end
end
