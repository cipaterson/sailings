# frozen_string_literal: true

Doorkeeper::OpenidConnect.configure do
  issuer do |_resource_owner, _application|
    Rails.application.credentials.oidc&.dig(:issuer) || Rails.application.routes.url_helpers.root_url
  end

  signing_key Rails.application.credentials.oidc&.dig(:signing_key)

  subject_types_supported [ :public ]

  resource_owner_from_access_token do |access_token|
    User.find_by(id: access_token.resource_owner_id)
  end

  auth_time_from_resource_owner do |resource_owner|
    resource_owner.sessions.order(created_at: :desc).first&.created_at
  end

  reauthenticate_resource_owner do |_resource_owner, return_to|
    # Force re-login if max_age is requested
    store_url = session[:return_to_after_authenticating]
    session[:return_to_after_authenticating] = return_to
    redirect_to new_session_url
    session[:return_to_after_authenticating] = store_url if store_url
  end

  subject do |resource_owner, _application|
    resource_owner.id.to_s
  end

  claims do
    normal_claim :email do |resource_owner|
      resource_owner.email_address
    end

    normal_claim :email_verified do |_resource_owner|
      true
    end

    normal_claim :name do |resource_owner|
      resource_owner.full_name
    end

    normal_claim :given_name do |resource_owner|
      resource_owner.first_name
    end

    normal_claim :family_name do |resource_owner|
      resource_owner.last_name
    end
  end
end
