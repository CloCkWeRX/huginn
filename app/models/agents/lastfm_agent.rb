# encoding: utf-8 
require 'open-uri'
require 'xmlsimple'

module Agents
  class LastfmAgent < Agent
    description <<-MD
    Ported from https://github.com/craigcoles/lastfm-widget

    Grabs the last played or currently playing track for a specified username.

    You'll need an API key (http://www.last.fm/api)
    MD

    event_description <<-MD
      Events are simply nested MQTT payloads. For example, an MQTT payload for Owntracks

      <pre><code>{ 
        "cover": "assets/no-album-art.jpg", 
        "artist":  "Derb",
        "track": "This is Derb", 
        "title": 'Now Playing'
      }</code></pre>
    MD

    def validate_options
      unless options['username'].present? &&
        options['api_key'].present?
        errors.add(:base, "username and api_key are required")
      end
    end

    def working?
      event_created_within?(options['expected_update_period_in_days']) && !recent_error_logs?
    end

    def default_options
      {
        'username' => '?',
        'api_key' => '?'
      }
    end

    def check
      http = Net::HTTP.new('ws.audioscrobbler.com')
      response = http.request(Net::HTTP::Get.new("/2.0/?method=user.getrecenttracks&user=#{username}&api_key=#{api_key}"))
      response_status = XmlSimple.xml_in(response.body, { 'ForceArray' => false })

      if response_status['status'] == "failed"
        raise response_status.inspect
      end

      user_id = XmlSimple.xml_in(response.body, { 'ForceArray' => false })['recenttracks']
      song = XmlSimple.xml_in(response.body, { 'ForceArray' => false })['recenttracks']['track'][0]

      song['nowplaying'] == "true" ? track_status = "Now Playing" : track_status = "Last Played"

      song['image'][2]['content'].nil? ? image = "assets/no-album-art.jpg" : image = song['image'][2]['content']

      create_event :payload => {
        :cover => image, 
        :artist => song['artist']['content'], 
        :track => song['name'], 
        :title => track_status
      }

    end

  end
end