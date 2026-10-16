# frozen_string_literal: true

require "cgi"

module Sso
  module Saml
    class RequestParser
      ISSUE_INSTANT_SKEW = 5.minutes
      REPLAY_TTL = 10.minutes

      def parse(raw_saml_request)
        raise Errors::InvalidSamlRequest if raw_saml_request.blank?

        request = SamlIdp::Request.from_deflated_request(raw_saml_request)
        unless request.authn_request? && request.issuer.present? && request.acs_url.present? && request.request_id.present?
          raise Errors::InvalidSamlRequest
        end

        node = request.request
        raise Errors::InvalidSamlRequest if node.blank?

        force_authn = xml_boolean(node["ForceAuthn"])
        is_passive = xml_boolean(node["IsPassive"])
        raise Errors::InvalidSamlRequest if force_authn && is_passive

        validate_destination!(node["Destination"])
        issue_instant = parse_issue_instant(node["IssueInstant"])

        ParsedRequest.new(
          entity_id: request.issuer,
          acs_url: request.acs_url,
          request_id: request.request_id,
          destination: node["Destination"],
          issue_instant: issue_instant,
          force_authn: force_authn,
          is_passive: is_passive
        )
      end

      def verify_query_signature!(raw_saml_request:, signature:, sig_algorithm:, relay_state:, certificate:)
        return if signature.blank?

        raise Errors::InvalidSamlRequest if raw_saml_request.blank? || sig_algorithm.blank? || certificate.blank?

        cert = OpenSSL::X509::Certificate.new(certificate)
        digest = signature_digest(sig_algorithm)
        raw_signature = Base64.decode64(signature)
        signed = query_string(raw_saml_request, relay_state, sig_algorithm)

        valid = cert.public_key.verify(digest.new, raw_signature, signed) ||
                cert.public_key.verify(digest.new, raw_signature, signed.gsub(/%[A-F0-9]{2}/, &:downcase))
        raise Errors::InvalidSamlRequest unless valid
      rescue OpenSSL::X509::CertificateError, OpenSSL::PKey::PKeyError
        raise Errors::InvalidSamlRequest
      end

      def self.claim_request_id!(request_id)
        raise Errors::InvalidSamlRequest if request_id.blank?

        unless Rails.cache.write("saml:authn:#{request_id}", true, expires_in: REPLAY_TTL, unless_exist: true)
          raise Errors::InvalidSamlRequest
        end
      end

      private

      def validate_destination!(destination)
        return if destination.blank?

        allowed = [
          SamlIdp.config.single_service_post_location,
          SamlIdp.config.single_service_redirect_location
        ].compact.uniq
        raise Errors::InvalidSamlRequest unless allowed.include?(destination)
      end

      def parse_issue_instant(value)
        raise Errors::InvalidSamlRequest if value.blank?

        instant = Time.iso8601(value)
        now = Time.now.utc
        raise Errors::InvalidSamlRequest unless instant.between?(now - ISSUE_INSTANT_SKEW, now + ISSUE_INSTANT_SKEW)

        instant
      rescue ArgumentError
        raise Errors::InvalidSamlRequest
      end

      def xml_boolean(value)
        return false if value.blank?

        value.to_s.casecmp("true").zero? || value.to_s == "1"
      end

      def signature_digest(sig_algorithm)
        sha_version = sig_algorithm.to_s[ /sha(\d+)$/i, 1 ].to_i
        case sha_version
        when 256 then OpenSSL::Digest::SHA256
        when 384 then OpenSSL::Digest::SHA384
        when 512 then OpenSSL::Digest::SHA512
        else
          raise Errors::InvalidSamlRequest
        end
      end

      def query_string(raw_saml_request, relay_state, sig_algorithm)
        url_string = "SAMLRequest=#{CGI.escape(raw_saml_request)}"
        url_string += "&RelayState=#{CGI.escape(relay_state)}" if relay_state.present?
        url_string + "&SigAlg=#{CGI.escape(sig_algorithm)}"
      end
    end
  end
end
