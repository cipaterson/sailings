FactoryBot.define do
  factory :sailing do
    purpose do
      [ "Full day sail", "Sail and Walk", "Tasports Grant", "School Group",
        "Training Voyage", "Charter", "General Maintenance", "MSR Drill" ].sample
    end
    sailing_type    { Sailing::SAILING_TYPES.sample }
    departs_at      { Time.current }
    returns_at      { departs_at + rand(4..8).hours }
    master          { %w[PM RC AF DA CJ].sample }
    passenger_count { rand(8..25) }
    comments        { nil }
    charterer       { nil }
    ln_contact      { nil }
    engineer        { nil }
  end
end
