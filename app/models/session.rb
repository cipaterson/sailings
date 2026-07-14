class Session < ApplicationRecord
  belongs_to :user

  # The raw bearer token, readable only on the session that just issued it. It is
  # never stored — only its digest is — so it cannot be recovered afterwards.
  attr_reader :token

  # Issues a session carrying a bearer token, for API clients that cannot hold a
  # signed cookie. Web sessions are created without one and leave token_digest nil.
  def self.start_with_token!(user, user_agent: nil, ip_address: nil)
    raw = SecureRandom.urlsafe_base64(32)
    session = create!(user: user, user_agent: user_agent, ip_address: ip_address,
                      token_digest: digest(raw))
    session.instance_variable_set(:@token, raw)
    session
  end

  def self.find_by_token(raw)
    return nil if raw.blank?

    find_by(token_digest: digest(raw))
  end

  def self.digest(raw)
    Digest::SHA256.hexdigest(raw)
  end
end
