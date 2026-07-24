#!/usr/bin/env ruby
# End-to-end HTTP benchmark, run from a workstation against a deployed server.
#
#   ruby script/bench.rb
#   HOST=https://staging.firstsoftware.cc N=15 ruby script/bench.rb
#
# Measures real latency over the wire — TLS, kamal-proxy, Puma and SQLite — so
# the numbers reflect what a user actually waits for on production-spec hardware.
#
# Environment:
#   HOST      base URL (default https://staging.firstsoftware.cc)
#   EMAIL     login (default perfbench@example.com, created by script/seed_perf.rb)
#   PASSWORD  login password (default Benchmark1)
#   N         timed iterations per endpoint (default 10)
#   WARMUP    untimed iterations per endpoint (default 2)
#   ONLY      substring filter, e.g. ONLY=csv
#
# SAFETY: this issues GET requests only, and refuses to do anything else.
# On a deployed server Rails.env is production, which makes
# config/initializers/brevo_delivery.rb send real email; SMS costs real money.
# Every mailer and SMS trigger in this app lives behind a POST/PATCH
# (registrations#create, sailing_participants#create/update/sms_accepted), so
# staying GET-only keeps the benchmark from spending money or spamming members.

require "net/http"
require "uri"
require "json"
require "time"

HOST     = ENV.fetch("HOST", "https://staging.firstsoftware.cc")
EMAIL    = ENV.fetch("EMAIL", "perfbench@example.com")
PASSWORD = ENV.fetch("PASSWORD", "Benchmark1")
N        = ENV.fetch("N", "10").to_i
WARMUP   = ENV.fetch("WARMUP", "2").to_i
ONLY     = ENV["ONLY"]

# ApplicationController declares `allow_browser versions: :modern`, which blocks
# unrecognised user agents with 406 before any action runs.
USER_AGENT = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 " \
             "(KHTML, like Gecko) Chrome/140.0.0.0 Safari/537.36"

base    = URI.parse(HOST)
cookies = {}

def cookie_header(cookies) = cookies.map { |k, v| "#{k}=#{v}" }.join("; ")

def absorb_cookies!(cookies, response)
  response.get_fields("set-cookie")&.each do |raw|
    name, value = raw.split(";").first.split("=", 2)
    cookies[name] = value
  end
end

http = Net::HTTP.new(base.host, base.port)
http.use_ssl = (base.scheme == "https")
http.open_timeout = 15
http.read_timeout = 180 # generous: unpaginated CSV on 1 core can be very slow
http.start

# --------------------------------------------------------------------- login

def get(http, cookies, path)
  req = Net::HTTP::Get.new(path)
  req["User-Agent"] = USER_AGENT
  req["Cookie"] = cookie_header(cookies) unless cookies.empty?
  res = http.request(req)
  absorb_cookies!(cookies, res)
  res
end

print "Signing in as #{EMAIL} ... "

login_page = get(http, cookies, "/session/new")
abort "\nGET /session/new returned #{login_page.code}" unless login_page.code == "200"

token = login_page.body[/name="authenticity_token"[^>]*value="([^"]+)"/, 1] ||
        login_page.body[/value="([^"]+)"[^>]*name="authenticity_token"/, 1]
abort "\nCould not find CSRF token on the login page" unless token

# The only non-GET request in this script, and the reason for it is unavoidable:
# every benchmarked page is behind authentication. sessions#create is rate
# limited to 10 per 3 minutes, so we log in once and reuse the cookie.
login = Net::HTTP::Post.new("/session")
login["User-Agent"]  = USER_AGENT
login["Cookie"]      = cookie_header(cookies)
login["Content-Type"] = "application/x-www-form-urlencoded"
login.body = URI.encode_www_form(
  authenticity_token: token, email_address: EMAIL, password: PASSWORD
)
res = http.request(login)
absorb_cookies!(cookies, res)

if res.code != "302"
  abort "\nLogin failed: expected 302, got #{res.code}"
end
if res["location"].to_s.include?("/session/new")
  abort "\nLogin rejected (redirected back to the sign-in page). Check EMAIL/PASSWORD, " \
        "and that the account is approved and has a role."
end
puts "ok"

# Confirm the session cookie actually authenticates before timing anything.
check = get(http, cookies, "/sailings")
abort "Authenticated check failed: GET /sailings returned #{check.code}" unless check.code == "200"

# Pick a real voyage id for the per-record endpoints.
sailing_id = check.body[%r{/sailings/(\d+)}, 1]
abort "Could not find a voyage id on /sailings — is the database seeded?" unless sailing_id
puts "Using voyage id #{sailing_id} for per-record endpoints"

# ----------------------------------------------------------------- endpoints

endpoints = [
  [ "index (page 1)",        "/sailings" ],
  [ "index deep offset",     "/sailings?page=90" ],
  # PER_PAGE is 15, so the all-time list runs to ~1,000 pages at the stress
  # tier. This lands near the end, where OFFSET has the most rows to skip.
  [ "index last page",       "/sailings?from_date=&page=#{ENV.fetch("LAST_PAGE", "990")}" ],
  [ "index status=done",     "/sailings?status=done" ],
  [ "index date range",      "/sailings?from_date=2022-01-01&to_date=2026-12-31" ],
  # index defaults @from_date to today, so a bare .csv only exports upcoming
  # voyages. An empty from_date makes Date.parse raise and rescue to nil, which
  # drops the filter entirely — this is the true unpaginated all-time export.
  [ "index CSV (upcoming)",  "/sailings.csv" ],
  [ "index CSV (all-time)",  "/sailings.csv?from_date=" ],
  [ "index all-time page 1", "/sailings?from_date=" ],
  [ "calendar month",        "/sailings/calendar?view=month" ],
  [ "calendar week",         "/sailings/calendar?view=week" ],
  [ "financials",            "/sailings/financials" ],
  [ "voyage show",           "/sailings/#{sailing_id}" ],
  [ "voyage manifest",       "/sailings/#{sailing_id}/manifest" ],
  [ "voyage crew list",      "/sailings/#{sailing_id}/sailing_participants" ],
  [ "users index",           "/users" ],
  [ "users search (LIKE)",   "/users?search=son" ],
  [ "users CSV (full)",      "/users.csv" ],
  [ "maintenance tasks",     "/maintenance_tasks" ],
  [ "my registrations",      "/my_registrations" ]
]
endpoints.select! { |name, path| "#{name} #{path}".include?(ONLY) } if ONLY

def pct(sorted, p)
  return nil if sorted.empty?
  sorted[[ (sorted.size * p).ceil - 1, 0 ].max]
end

results = []

puts "\nBenchmarking #{endpoints.size} endpoints against #{HOST} " \
     "(#{WARMUP} warmup + #{N} timed each)\n\n"

endpoints.each do |name, path|
  WARMUP.times { get(http, cookies, path) rescue nil }

  samples = []
  bytes   = nil
  status  = nil
  error   = nil

  N.times do
    started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    begin
      req = Net::HTTP::Get.new(path)
      req["User-Agent"] = USER_AGENT
      req["Cookie"] = cookie_header(cookies)

      http.request(req) do |res|
        body = res.read_body
        status = res.code
        bytes  = body.bytesize
      end
      samples << (Process.clock_gettime(Process::CLOCK_MONOTONIC) - started) * 1000
    rescue StandardError => e
      error = "#{e.class}: #{e.message}"
      # A dead socket means the server likely died (OOM on 1 GB / no swap).
      # Reconnect so the remaining endpoints still get measured.
      begin
        http.finish if http.started?
        http.start
      rescue StandardError
        nil
      end
      break
    end
  end

  sorted = samples.sort
  row = {
    name: name, path: path, status: status, bytes: bytes,
    n: samples.size, error: error,
    min: sorted.first&.round(1), p50: pct(sorted, 0.5)&.round(1),
    p90: pct(sorted, 0.9)&.round(1), max: sorted.last&.round(1)
  }
  results << row

  flag = if error then "ERROR"
  elsif status != "200" then "HTTP #{status}"
  else ""
  end

  printf("  %-22s %8s %8s %8s  %9s  %s\n",
         name,
         row[:p50] ? "#{row[:p50]}ms" : "-",
         row[:p90] ? "#{row[:p90]}ms" : "-",
         row[:max] ? "#{row[:max]}ms" : "-",
         bytes ? "#{(bytes / 1024.0).round(1)}KB" : "-",
         flag)
  $stdout.flush
end

http.finish if http.started?

# -------------------------------------------------------------------- report

puts "\n#{"=" * 78}"
printf("%-22s %9s %9s %9s %10s %8s\n", "ENDPOINT", "p50", "p90", "max", "size", "status")
puts "-" * 78
results.each do |r|
  printf("%-22s %9s %9s %9s %10s %8s\n",
         r[:name],
         r[:p50] ? "#{r[:p50]}ms" : "-",
         r[:p90] ? "#{r[:p90]}ms" : "-",
         r[:max] ? "#{r[:max]}ms" : "-",
         r[:bytes] ? "#{(r[:bytes] / 1024.0).round(1)}KB" : "-",
         r[:error] ? "ERR" : r[:status])
end
puts "=" * 78

failed = results.select { |r| r[:error] || r[:status] != "200" }
if failed.any?
  puts "\nProblems:"
  failed.each { |r| puts "  #{r[:name]} (#{r[:path]}): #{r[:error] || "HTTP #{r[:status]}"}" }
end

require "fileutils"
FileUtils.mkdir_p("tmp/bench")
stamp = Time.now.utc.strftime("%Y%m%dT%H%M%SZ")
label = ENV.fetch("LABEL", "run")
file  = "tmp/bench/#{stamp}-#{label}.json"
File.write(file, JSON.pretty_generate(
  host: HOST, recorded_at: Time.now.utc.iso8601,
  iterations: N, warmup: WARMUP, label: label, results: results
))
puts "\nWrote #{file}"
