FactoryBot.define do
  factory :maintenance_task do
    problem_description do
      [
        "Capping rail near port stern has some rot",
        "Lizard on fore course port brace frayed",
        "Tear in bottom edge of Fisherman",
        "Starboard chainplate showing surface rust",
        "Bowsprit gammoning seized and needs reseizing",
        "Foremast stay chafing at spreader",
        "Bilge pump handle missing",
        "Compass light not working",
        "Navigation light (port) flickering",
        "Winch handle broken - stbd aft",
        "Deck leak above forward cabin bunk",
        "Galley fresh water pump losing prime",
        "Main halyard block seized",
        "Topsail sheet showing wear at cleat",
        "Fire extinguisher in engine room overdue for service",
        "Engine cooling water temp running high",
        "Anchor windlass gypsy slipping",
        "Heads seacock stiff to operate",
        "Flare kit expiry date passed",
        "Life ring bracket broken on port side"
      ].sample
    end
    priority      { MaintenanceTask::PRIORITIES.sample }
    state         { "Reported" }
    date_reported { Faker::Time.between(from: 90.days.ago, to: 1.day.ago) }
    who_reported  { "1" }
    date_fixed    { nil }
    who_fixed     { nil }
    fixed_note    { nil }
    comments      { nil }
  end
end
