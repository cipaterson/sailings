# The signed-in member's own record: identity, sailing record, and the
# qualifications whose expiry drives the "am I current?" screen.
class ProfileSerializer
  # Each qualification on User is a trio of <name>_qualification / _issued_on /
  # _expires_on columns.
  QUALIFICATIONS = {
    "ess" => "ESS",
    "med" => "MED",
    "wwvp" => "WWVP",
    "first_aid" => "First Aid",
    "coxswain" => "Coxswain",
    "food_handling" => "Food Handling"
  }.freeze

  # Training milestones are single dates rather than expiring qualifications.
  TRAINING_DATES = {
    "sit_date" => "SIT1",
    "sit2_date" => "SIT2",
    "marine_safety_refresher_on" => "Marine Safety Refresher",
    "knots_on" => "Knots"
  }.freeze

  def initialize(user)
    @user = user
  end

  def as_json(*)
    {
      id: @user.id,
      email_address: @user.email_address,
      first_name: @user.first_name,
      last_name: @user.last_name,
      full_name: @user.full_name,
      membership_type: @user.membership_type,
      date_joined: @user.date_joined&.iso8601,
      roles: @user.roles,
      skills: @user.skills,
      sailing_record: {
        days_sailed: @user.days_sailed.to_i,
        last_sailed: @user.last_sailed&.iso8601,
        sailing_class: @user.sailing_class
      },
      qualifications: qualifications,
      training: training
    }
  end

  private

  def qualifications
    QUALIFICATIONS.map do |field, label|
      {
        key: field,
        label: label,
        value: @user.public_send(:"#{field}_qualification"),
        issued_on: @user.public_send(:"#{field}_issued_on")&.iso8601,
        expires_on: @user.public_send(:"#{field}_expires_on")&.iso8601
      }
    end
  end

  def training
    TRAINING_DATES.map do |field, label|
      { key: field, label: label, completed_on: @user.public_send(field)&.iso8601 }
    end
  end
end
