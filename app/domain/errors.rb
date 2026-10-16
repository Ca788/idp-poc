# frozen_string_literal: true

module Errors
  class DomainError < StandardError; end

  class OrganizationNotFound < DomainError; end
  class InvalidCredentials < DomainError; end
  class UserInactive < DomainError; end
  class ClientApplicationNotFound < DomainError; end
  class ClientApplicationInactive < DomainError; end
  class UnsupportedProtocol < DomainError; end
  class CrossOrganizationAccess < DomainError; end
  class InvalidSamlRequest < DomainError; end
  class InvalidAcsUrl < DomainError; end
  class MissingSpCertificate < DomainError; end
  class ExpiredSpCertificate < DomainError; end
  class SsoSessionRequired < DomainError; end
  class LoginRateLimited < DomainError; end
end
