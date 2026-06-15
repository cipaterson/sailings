FactoryBot.define do
  factory :sailing do
    purpose do
      [ "HS x2", "Sail and Walk", "Tasports Grant", "School Group",
        "SIT1", "SIT2", "Charter", "General Maintenance", "MSR Drill" ].sample
    end
    status          { "scheduled" }
    departs_at      { Time.current }
    returns_at      { departs_at + rand(4..8).hours }
    master          { %w[PM RC AF DA CJ].sample }
    passenger_count { rand(8..25) }
    comments        { nil }
    ln_contact      { %w[CJ JD Crewing].sample }
    engineer        { nil }

    sailing_type do
      case purpose
      when "SIT1", "SIT2"        then "Other"
      when "General Maintenance" then "Maintenance"
      when "School Group", "Tasports Grant", "Charter", "HS x2", "MSR Drill" then "Sail"
      else Sailing::SAILING_TYPES.sample
      end
    end

    training do
      case purpose
      when "SIT1"      then "SIT1"
      when "SIT2"      then "SIT2"
      when "MSR Drill" then "MSR"
      end
    end

    charterer do
      case purpose
      when "School Group"   then "School"
      when "Tasports Grant" then "TasPorts"
      when "Charter"        then "JohnSmith"
      end
    end
  end
end
