# frozen_string_literal: true

class UseCase::Sso::IssueAssertionUseCase
  def initialize(user_repo: User, client_repo: ClientApplication)
    @user_repo = user_repo
    @client_repo = client_repo
  end

  # @param [String] organization_id
  # @param [String] user_id
  # @param [String] client_application_id
  # @return [Models::IdentityAssertion]
  def call(organization_id:, user_id:, client_application_id:)
    user = @user_repo.for_organization(organization_id).find_by(id: user_id)
    raise Errors::InvalidCredentials unless user
    raise Errors::UserInactive unless user.active?

    client = @client_repo.for_organization(organization_id).find_by(id: client_application_id)
    raise Errors::ClientApplicationNotFound unless client
    raise Errors::ClientApplicationInactive unless client.active?

    Models::IdentityAssertion.new(
      subject: user.id,
      email: user.email,
      first_name: user.first_name,
      last_name: user.last_name,
      organization_id: organization_id,
      client_application_id: client.id
    )
  end
end
