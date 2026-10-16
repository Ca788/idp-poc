# frozen_string_literal: true

class UseCase::Identity::ResolveSessionUseCase
  def initialize(session_repo: IdentitySession)
    @session_repo = session_repo
  end

  # @param [String] token
  # @return [IdentitySession]
  def call(token:)
    raise Errors::SsoSessionRequired if token.blank?

    record = @session_repo.active.find_by(token_digest: @session_repo.digest(token))
    raise Errors::SsoSessionRequired unless record

    record
  end
end
