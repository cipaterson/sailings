class SailingManifestPdf
  include Prawn::View

  HEADER_COLOR = "003366"
  ROW_COLOR    = "FFFFFF"
  ALT_COLOR    = "EEF2F7"

  def initialize(sailing, participants)
    @sailing      = sailing
    @participants = participants.select { |p| p.status == "Accepted" }
    @document     = Prawn::Document.new(page_size: "A4", page_layout: :landscape, margin: 28)
    build
  end

  private

  def build
    heading
    sailing_details
    move_down 12
    participants_table
  end

  def heading
    text "Lady Nelson — Sailing Manifest", size: 18, style: :bold, color: HEADER_COLOR
    text "Generated: #{Date.today.strftime("%d %b %Y")}", size: 9, color: "666666"
    move_down 6
    stroke_horizontal_rule
    move_down 8
  end

  def sailing_details
    rows = [
      [ "Purpose",   @sailing.purpose,                   "Master",   @sailing.master ],
      [ "Departs",   format_datetimeday(@sailing.departs_at), "Returns",  format_datetime(@sailing.returns_at) ],
      [ "Charterer", @sailing.charterer,                  "LN Contact", @sailing.ln_contact ],
      [          "Passengers", @sailing.passenger_count ]
    ]

    table(rows, width: bounds.width, cell_style: { border_width: 0, padding: [ 2, 6 ] }) do
      column(0).font_style = :bold
      column(0).width = 70
      column(2).font_style = :bold
      column(2).width = 70
    end
  end

  def participants_table
    text "Participants (#{@participants.size})", size: 12, style: :bold, color: HEADER_COLOR
    move_down 4

    headers = [ "Name", "Mobile", "ESS", "Class", "MED", "WWVP Expires", "MSR" ]

    data = @participants.map do |p|
      u = p.user
      [
        u.full_name,
        u.contact&.mobile.to_s,
        u.ess_qualification.to_s,
        u.sailing_class.to_s,
        u.med_qualification.to_s,
        format_date(u.wwvp_expires_on),
        format_date(u.marine_safety_refresher_on)
      ]
    end

    table([ headers ] + data, width: bounds.width, header: true) do
      row(0).background_color = HEADER_COLOR
      row(0).text_color        = "FFFFFF"
      row(0).font_style        = :bold
      row(0).size              = 9

      rows(1..-1).each_with_index do |row, i|
        row.background_color = i.even? ? ROW_COLOR : ALT_COLOR
      end

      cells.size    = 8
      cells.padding = [ 3, 4 ]
      cells.border_width = 0.5
      cells.border_color = "CCCCCC"
    end
  end

  def format_datetime(dt)
    dt ? dt.strftime("%d %b %Y %H:%M") : ""
  end

  def format_datetimeday(dt)
    dt ? dt.strftime("%A %d %b %Y %H:%M") : ""
  end

  def format_date(d)
    d ? d.strftime("%d %b %Y") : ""
  end
end
