# frozen_string_literal: true

module Api
  module V1
    class ClientApplicationsController < ApplicationController
      include ApiPagination

      def index
        scope = UseCase::Client::ListClientApplicationsUseCase.new.call(
          organization_id: current_organization.id,
          fields: params[:fields].to_s.split(",").map(&:strip)
        )

        records = paginate(scope)

        render json: {
          data: records.as_json,
          meta: {
            page: records.current_page,
            per_page: records.limit_value,
            total: records.total_count
          }
        }
      end

      def create
        client = UseCase::Client::RegisterClientApplicationUseCase.new.call(
          organization_id: current_organization.id,
          name: params.require(:name),
          protocol: params.require(:protocol),
          entity_id: params.require(:entity_id),
          acs_url: params.require(:acs_url),
          sp_certificate: params[:sp_certificate]
        )

        render json: { data: client.as_json }, status: :created
      end
    end
  end
end
