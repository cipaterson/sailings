# Configure the litestream-ruby gem.
#
# Non-secret replica settings come from ENV, injected by Kamal in production as
# clear env (see config/deploy.prod.yml). The DigitalOcean Spaces keys are read
# from the encrypted Rails credentials (decrypted at runtime via RAILS_MASTER_KEY),
# so they never travel through Kamal secrets or the environment. Add them with
# `bin/rails credentials:edit`:
#
#   litestream:
#     access_key_id: <spaces key>
#     secret_access_key: <spaces secret>
#
# The gem propagates these onto the ENV variables referenced in config/litestream.yml
# (e.g. replica_key_id -> LITESTREAM_ACCESS_KEY_ID) when it runs the litestream binary.
#
# Litestream replication only runs where LITESTREAM_REPLICA_BUCKET is present
# (see the `plugin :litestream` guard in config/puma.rb), so staging and
# development never replicate.
Rails.application.configure do
  config.litestream.replica_bucket = ENV["LITESTREAM_REPLICA_BUCKET"]
  config.litestream.replica_endpoint = ENV["LITESTREAM_REPLICA_ENDPOINT"]
  config.litestream.replica_region = ENV["LITESTREAM_REPLICA_REGION"]
  config.litestream.replica_key_id = Rails.application.credentials.dig(:litestream, :access_key_id)
  config.litestream.replica_access_key = Rails.application.credentials.dig(:litestream, :secret_access_key)
end
