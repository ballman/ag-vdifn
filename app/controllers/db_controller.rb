# coding: utf-8
class DbController < ApplicationController

  HOST = ENV['AG_WEATHER_BASE_URL'] || 'http://localhost:3000'

  def severities
    pest = Pest.find(params[:pest_id])
    render json: pest.severities(start_date, end_date)
  end

  def stations
    url = "#{HOST}/stations"
    response = HTTParty.get(url, { timeout: 10 })
    @stations = JSON.parse(response.body)
    render json: @stations
  end

  # http://agweather.cals.wisc.edu/ag_weather/pest_forecasts/point_details?pest=onion_maggot&start_date=2019-01-01&end_date=2019-03-13&longitude=89.8&latitude=45.2
  def point_details
    @pest = Pest.find(params[:pest_id])
    @latitude = params[:latitude].to_f.round(1)
    @longitude = params[:longitude].to_f.round(1)
    url = "#{HOST}/pest_forecasts/point_details?pest=#{@pest.remote_name}&start_date=#{start_date}&end_date=#{end_date}&longitude=#{@longitude}&latitude=#{@latitude}"

    response = HTTParty.get(url, { timeout: 10 })
    @weather = JSON.parse(response.body)
    render layout: false
  end

  def station_details
    @name = params[:name]
    url = "#{HOST}/station_observations?name=#{@name}&start_date=#{start_date}&end_date=#{end_date}"

    response = HTTParty.get(url, { timeout: 10 })
    @weather = JSON.parse(response.body)
    render layout: false
  end

  def severity_legend
    pest = Pest.find(params[:pest_id])
    @severities = pest.severity_legend
    render layout: false
  end

  def pest_info
    pest = Pest.find(params[:pest_id])
    in_f = params[:in_fahrenheit] == 'true'
    info = pest.info
    info.prepend(ActionController::Base.helpers.image_tag(pest.photo, width: '100px')) unless pest.photo.blank?
    info += " <a href=http://#{pest.link} target='_blank'>More information…</a>" unless pest.link.blank?

    render json: {
             info: info,
             name: pest.name,
             pest_link: pest.link,
             biofix: pest.biofix_date,
             end_date_enabled: pest.end_date_enabled?,
             tmin: in_f ? pest.t_min : convert_temp(pest.t_min),
             tmax: pest.t_max.nil? ? '' : (in_f ? pest.t_max : convert_temp(pest.t_max))
           }
  end

  private
  def start_date
    params[:start_date].blank? ? Date.current - 7.days : Date.parse(params[:start_date])
  end

  def end_date
    params[:end_date].blank? ? Date.current : Date.parse(params[:end_date])
  end

  def convert_temp(temp)
    return 0 if temp.nil?
    ((temp - 32) * 5.0/9.0).round(1)
  end
end
