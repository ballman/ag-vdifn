# coding: utf-8
class LateBlight < DsvPest

  def severities(start_date, end_date)
    past_week = get_remote_totals(end_date - 7.days, end_date)
    season_to_date = get_remote_totals(end_date.beginning_of_year, end_date)
    return severities_from_totals(past_week, season_to_date)
  end

  def severities_from_totals(past_week, season_to_date)

    if past_week.count != season_to_date.count
      logger.error("Potato Late Blight: past week and season mismatch")
      return []
    end

    past_week.zip(season_to_date).map do | pair |
      logger.error("Potato Late Blight: Latitude mismatch") if pair[0]["lat"] != pair[1]["lat"]
      logger.error("Potato Late Blight: Longitude mismatch") if pair[0]["long"] != pair[1]["long"]
      last_week = pair[0]["total"]
      season = pair[1]["total"]
      {
        lat: pair[0]['lat'],
        long: pair[0]['long'],
        severity: total_to_severity(last_week, season)
      }
    end
  end

  def total_to_severity(last_week, season)
    if last_week <= 3 && season < 30
      return 0
    elsif last_week > 21
      return 4
    elsif last_week >= 3 || season >= 30
      return 2
    end
  end

  def severity_legend
    [
      {name: "High", slug: "very_high", description: "High likelihood of disease
(widespread outbreak observed OR 7-day accumulated DSVs ≥ 21 or isolated outbreak observed)"},
      {name: "Medium", slug: "medium", description: "Medium likelihood of disease
(7-day accumulated DSVs ≥ 3 or season accumulated DSVs > 30)"},
      {name: "Low", slug: "very_low", description: "Low likelihood of disease
(7-day accumulated DSVs ≤ 3 and season accumulated DSVs < 30)"}
    ]
  end

  def biofix_date
    7.days.ago.to_date
  end

  def end_date_enabled?
    return false
  end
end
