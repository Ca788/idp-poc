# frozen_string_literal: true

module Sso
  class IdpKeyMaterial
    class << self
      def certificate
        pair.fetch(:certificate)
      end

      def private_key
        pair.fetch(:private_key)
      end

      def pair
        @pair ||= load_pair
      end

      def reset!
        @pair = nil
      end

      private

      def load_pair
        if ENV["IDP_X509_CERTIFICATE"].present?
          {
            certificate: ENV["IDP_X509_CERTIFICATE"],
            private_key: ENV.fetch("IDP_PRIVATE_KEY")
          }
        elsif Rails.env.production?
          raise "IDP_X509_CERTIFICATE and IDP_PRIVATE_KEY are required in production"
        else
          read_or_generate_dev_pair
        end
      end

      def read_or_generate_dev_pair
        dir = Rails.root.join("tmp/certs")
        FileUtils.mkdir_p(dir)
        crt = dir.join("idp.crt")
        key = dir.join("idp.key")

        unless crt.exist? && key.exist?
          generated = generate
          crt.write(generated[:certificate])
          key.write(generated[:private_key])
        end

        { certificate: crt.read, private_key: key.read }
      end

      def generate
        rsa = OpenSSL::PKey::RSA.new(2048)
        cert = OpenSSL::X509::Certificate.new
        cert.version = 2
        cert.serial = 1
        cert.subject = cert.issuer = OpenSSL::X509::Name.parse("/CN=idp-dev")
        cert.public_key = rsa.public_key
        cert.not_before = Time.current - 1.day
        cert.not_after = Time.current + 10.years
        cert.sign(rsa, OpenSSL::Digest::SHA256.new)

        { certificate: cert.to_pem, private_key: rsa.to_pem }
      end
    end
  end
end
