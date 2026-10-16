# frozen_string_literal: true

module LoginRateLimit
  extend ActiveSupport::Concern

  LOGIN_RATE_LIMIT = 10
  LOGIN_RATE_WINDOW = 15.minutes

  private

  def enforce_login_rate_limit!
    count = Rails.cache.read(login_rate_limit_key).to_i
    raise Errors::LoginRateLimited if count >= LOGIN_RATE_LIMIT
  end

  def record_login_failure
    key = login_rate_limit_key
    Rails.cache.write(key, Rails.cache.read(key).to_i + 1, expires_in: LOGIN_RATE_WINDOW)
  end

  def clear_login_rate_limit
    Rails.cache.delete(login_rate_limit_key)
  end

  def login_rate_limit_key
    email = params[:email].to_s.strip.downcase
    "login:#{request.remote_ip}:#{email}"
  end
end
