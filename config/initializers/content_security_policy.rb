# Be sure to restart your server when you modify this file.

# Define an application-wide content security policy.
# See the Securing Rails Applications Guide for more information:
# https://guides.rubyonrails.org/security.html#content-security-policy-header

Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :self
    policy.font_src    :self, :data
    policy.img_src     :self, :data
    policy.object_src  :none
    policy.script_src  :self, :https
    policy.style_src   :self, :unsafe_inline, "https://cdn.simplecss.org", "https://cdn.jsdelivr.net" # unsafe_inline needed for Turbo's inline styles
    policy.connect_src :self, "https://cdn.jsdelivr.net"
    # Specify URI for violation reports
    # policy.report_uri "/csp-violation-report-endpoint"
  end

  # Nonce allows the importmap inline script tag (and therefore Turbo/Stimulus) through CSP
  config.content_security_policy_nonce_generator = ->(request) { request.session.id.to_s }
  config.content_security_policy_nonce_directives = %w[script-src]
end
