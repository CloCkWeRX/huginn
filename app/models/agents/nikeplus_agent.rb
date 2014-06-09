# encoding: utf-8 
require "nike_v2"
require "json"
require "net/http"

module Agents
  class NikeplusAgent < Agent
    description <<-MD
      Ported from https://github.com/danillotuhumury/nikeplus-dashing-widget

      Installation
      You'll have to request an Access Token from Nike+ (Nike didn't release the OAuth API yet.) With this Access Token you'll be able to retrieve data from you Nike+ account.

      https://developer.nike.com/index.html
    MD

    event_description <<-MD
      Returns a combined object of the activity data and GPS data.
      
      <pre><code>{
    "data": {
        "links": [{
            "rel": "self",
            "href": "https://api.nike.com/v1/me/sport/activities/2683000000011936851080007062707485942202"
        }],
        "activityId": "2683000000011936851080007062707485942202",
        "activityType": "RUN",
        "startTime": "2009-12-12T14:28:36Z",
        "activityTimeZone": "America/Dawson",
        "status": "COMPLETE",
        "deviceType": "SPORTWATCH",
        "metricSummary": {
            "calories": "295",
            "fuel": "1945",
            "distance": "9.19890022277832",
            "steps": "0",
            "duration": "0:22:26.000"
        },
        "tags": [{
            "tagType": "TERRAIN",
            "tagValue": "TRAIL"
        }, {
            "tagType": "WEATHER",
            "tagValue": "SUNNY"
        }],
        "metrics": [{
            "intervalMetric": 10,
            "intervalUnit": "SEC",
            "metricType": "DISTANCE",
            "values": [
                "0.025399999999999992",
                "0.026800000000000004",
                "0.027399999999999994",
                "0.025800000000000017"
            ]
        }],
        "isGpsActivity": true
    },
    "gps_data": {
        "links": [{
            "rel": "self",
            "href": "https://api.nike.com/v1/me/sport/activities/2683000000011936851080007062707485942202/gps"
        }, {
            "rel": "activity",
            "href": "https://api.nike.com/v1/me/sport/activities/2683000000011936851080007062707485942202"
        }],
        "elevationLoss": 65.70621,
        "elevationGain": 65.80545,
        "elevationMax": 13.911795,
        "elevationMin": 0.69595414,
        "intervalMetric": 10,
        "intervalUnit": "SEC",
        "waypoints": [{
            "latitude": 45.526386,
            "longitude": -122.6702,
            "elevation": 7.9260945
        }, {
            "latitude": 45.526386,
            "longitude": -122.6702,
            "elevation": 7.9260945
        }, {
            "latitude": 45.52639,
            "longitude": -122.670204,
            "elevation": 7.9367223
        }, {
            "latitude": 45.526398,
            "longitude": -122.670204,
            "elevation": 7.949546
        }, {
            "latitude": 45.52641,
            "longitude": -122.67021,
            "elevation": 7.977135
        }]
    }
}</code></pre>     
    MD

    def validate_options
      unless options['access_token'].present?
        errors.add(:access_token, "required")
      end
    end

    def working?
      event_created_within?(options['expected_update_period_in_days']) && !recent_error_logs?
    end

    def default_options
      {
        'access_token' => '?',
      }
    end

    def check
      person   = NikeV2::Person.new(access_token: options['access_token'])
      activity = person.activities.first
      
      if activity
        create_event :payload => { 
          data: activity.fetch_data
          gps_data: activity.gps_data
        }
      end
    end

  end
end