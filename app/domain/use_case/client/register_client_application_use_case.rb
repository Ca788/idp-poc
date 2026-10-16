# frozen_string_literal: true

class UseCase::Client::RegisterClientApplicationUseCase
  def initialize(client_repo: ClientApplication)
    @client_repo = client_repo
  end

  # @param [String] organization_id
  # @param [String] name
  # @param [String] protocol
  # @param [String] entity_id
  # @param [String] acs_url
  # @param [String, nil] sp_certificate
  # @return [ClientApplication]
  def call(organization_id:, name:, protocol:, entity_id:, acs_url:, sp_certificate: nil)
    unless ClientApplication::PROTOCOLS.include?(protocol.to_s)
      raise Errors::UnsupportedProtocol, protocol.to_s
    end

    @client_repo.create!(
      organization_id: organization_id,
      name: name,
      protocol: protocol.to_s,
      entity_id: entity_id,
      acs_url: acs_url,
      sp_certificate: sp_certificate,
      active: true
    )
  end
end
