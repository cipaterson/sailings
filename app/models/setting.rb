# Small cached key/value store backing the AppConfig façade. Values are JSON, so
# a setting can hold a scalar (e.g. the office email string) or a structure (e.g.
# the charter colors hash). Read through AppConfig, not directly, from app code.
class Setting < ApplicationRecord
  CACHE_KEY = "app_settings".freeze

  validates :key, presence: true, uniqueness: true

  after_commit :clear_cache

  # One cached hash of every setting; a single query on cache miss.
  def self.all_values
    Rails.cache.fetch(CACHE_KEY) { all.to_h { |s| [ s.key, s.value ] } }
  rescue ActiveRecord::StatementInvalid
    {} # table not migrated yet (e.g. asset precompile / fresh boot)
  end

  def self.[](key)
    all_values[key]
  end

  def self.write(key, value)
    find_or_initialize_by(key: key).update!(value: value)
  end

  private

  def clear_cache
    Rails.cache.delete(CACHE_KEY)
  end
end
