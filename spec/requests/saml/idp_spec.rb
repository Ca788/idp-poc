# frozen_string_literal: true

require "rails_helper"

RSpec.describe "SAML IdP" do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization, password: "secret123") }
  let(:client) do
    create(
      :client_application,
      organization: organization,
      protocol: "saml",
      acs_url: "https://app.example.test/sso/callback",
      sp_certificate: sp_certificate_pem
    )
  end
  let(:saml_request) do
    deflated_saml_request(entity_id: client.entity_id, acs_url: client.acs_url)
  end

  def login!
    post "/login", params: {
      organization_slug: organization.slug,
      email: user.email,
      password: "secret123"
    }
  end

  describe "GET /saml/metadata" do
    it "returns signed IdP metadata without announcing SLO" do
      get "/saml/metadata"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("EntityDescriptor")
      expect(response.body).to include("IDPSSODescriptor")
      expect(response.body).not_to include("SingleLogoutService")
    end
  end

  describe "GET /saml/auth" do
    it "redirects to login when there is no session" do
      get "/saml/auth", params: { SAMLRequest: saml_request, RelayState: "state-1" }

      expect(response).to redirect_to(login_path)
    end

    it "posts an encrypted assertion with InResponseTo after login" do
      get "/saml/auth", params: { SAMLRequest: saml_request, RelayState: "state-1" }
      login!
      follow_redirect!

      expect(response).to have_http_status(:ok)
      expect(response.headers["Cache-Control"]).to include("no-store")
      expect(response.body).to include("https://app.example.test/sso/callback")
      expect(response.body).to include("SAMLResponse")
      expect(response.body).to include("state-1")

      encoded = response.body[/name="SAMLResponse"[^>]*value="([^"]+)"/, 1]
      xml = Base64.decode64(CGI.unescapeHTML(encoded.to_s))
      expect(xml).to include("EncryptedAssertion")
      expect(xml).to include('InResponseTo="_req-1"')
      expect(xml).not_to include(user.email)
    end

    it "rotates the cookie session on login" do
      get "/saml/auth", params: { SAMLRequest: saml_request }
      sid_before = cookies["_idp_session"]
      login!

      expect(cookies["_idp_session"]).to be_present
      expect(cookies["_idp_session"]).not_to eq(sid_before)
    end

    it "rejects a Destination that is not the IdP SSO URL" do
      raw = deflated_saml_request(
        entity_id: client.entity_id,
        acs_url: client.acs_url,
        destination: "https://evil.example.test/saml"
      )

      get "/saml/auth", params: { SAMLRequest: raw }

      expect(response).to have_http_status(:bad_request)
      expect(response.body).to eq("InvalidSsoRequest")
    end

    it "rejects a replayed AuthnRequest id" do
      get "/saml/auth", params: { SAMLRequest: saml_request }
      login!
      follow_redirect!
      expect(response).to have_http_status(:ok)

      get "/saml/auth", params: { SAMLRequest: saml_request }

      expect(response).to have_http_status(:bad_request)
      expect(response.body).to eq("InvalidSsoRequest")
    end

    it "does not complete SSO for a client in another organization" do
      other_user = create(:user, password: "secret123")

      get "/saml/auth", params: { SAMLRequest: saml_request }
      post "/login", params: {
        organization_slug: other_user.organization.slug,
        email: other_user.email,
        password: "secret123"
      }
      follow_redirect!

      expect(response).to have_http_status(:bad_request)
      expect(response.body).to eq("InvalidSsoRequest")
    end

    it "does not show a login form for IsPassive without a session" do
      raw = deflated_saml_request(
        entity_id: client.entity_id,
        acs_url: client.acs_url,
        is_passive: true
      )

      get "/saml/auth", params: { SAMLRequest: raw }

      expect(response).to have_http_status(:bad_request)
      expect(response.body).to eq("InvalidSsoRequest")
    end

    it "requires a new login when ForceAuthn is set on an old session" do
      login!
      raw = deflated_saml_request(
        entity_id: client.entity_id,
        acs_url: client.acs_url,
        request_id: "_req-force",
        force_authn: true
      )

      get "/saml/auth", params: { SAMLRequest: raw }
      expect(response).to redirect_to(login_path)

      login!
      follow_redirect!
      expect(response).to have_http_status(:ok)

      encoded = response.body[/name="SAMLResponse"[^>]*value="([^"]+)"/, 1]
      xml = Base64.decode64(CGI.unescapeHTML(encoded.to_s))
      expect(xml).to include('InResponseTo="_req-force"')
    end
  end
end
