# frozen_string_literal: true

class UseCase::Sso::FindClientApplicationUseCase
  def initialize(client_repo: ClientApplication)
    @client_repo = client_repo
  end

  # @param [String] organization_id
  # @param [String] entity_id
  # @param [String] acs_url
  # @return [ClientApplication]
  def call(organization_id:, entity_id:, acs_url:)
    client = @client_repo.for_organization(organization_id).find_by(entity_id: entity_id)
    raise Errors::ClientApplicationNotFound unless client
    raise Errors::ClientApplicationInactive unless client.active?
    raise Errors::InvalidAcsUrl unless client.acs_url == acs_url

    client
  end
end
