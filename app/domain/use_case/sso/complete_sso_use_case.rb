# frozen_string_literal: true

class UseCase::Sso::CompleteSsoUseCase
  def initialize(
    issue_assertion: UseCase::Sso::IssueAssertionUseCase.new,
    issuer_factory: Sso::IssuerFactory
  )
    @issue_assertion = issue_assertion
    @issuer_factory = issuer_factory
  end

  # @param [String] organization_id
  # @param [String] user_id
  # @param [String] client_application_id
  # @param [String, nil] relay_state
  # @param [String, nil] request_id
  # @return [Models::SsoResponse]
  def call(organization_id:, user_id:, client_application_id:, relay_state: nil, request_id: nil)
    assertion = @issue_assertion.call(
      organization_id: organization_id,
      user_id: user_id,
      client_application_id: client_application_id
    )

    client = ClientApplication.for_organization(organization_id).find_by(id: client_application_id)
    raise Errors::ClientApplicationNotFound unless client

    payload = @issuer_factory.build(client.protocol).issue(
      assertion: assertion,
      client_application: client,
      request_id: request_id
    )

    Models::SsoResponse.new(
      payload: payload,
      acs_url: client.acs_url,
      relay_state: relay_state,
      protocol: client.protocol
    )
  end
end
