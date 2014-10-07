module Api::V1
  class ApiController < ApplicationController

    skip_before_action :validate_token, only: [:error]

    rescue_from ActiveRecord::RecordNotFound, with: :not_found
    rescue_from StandardError, with: :error_500
    rescue_from CanCan::AccessDenied, with: :error_403

    private

    def not_found
      render json: {}, status: :not_found
    end

    def error_500(exception)
      Rails.logger.error(exception)
      exception.backtrace.each{|e| Rails.logger.error(e)}
      raise(exception) if Rails.env == "test"
      render json: {}, status: '500'
    end

    def error_403
      throw(:warden, {status: 403, message: I18n.t('warden.unauthorized'), value: false}) if request.format.json?
      render(file: "#{Rails.root}/public/403.#{I18n.locale}.html", status: 403, layout: false) if request.format.html?
    end

  end
end
