require "json"
require "yaml"
require "nokogiri"
require "oauth"

ACCESS_TOKEN = File.read("#{File.dirname(__FILE__)}/access_token.txt")

response = JSON.parse(`curl -X POST https://www.strava.com/oauth/token -F client_id=1924 -F client_secret=097a5cbf7da9d0d9aa80ebd50497d20d927321e6 -F code=#{ACCESS_TOKEN} -F grant_type=authorization_code`)
activities = JSON.parse(`curl -G https://www.strava.com/api/v3/activities -H "Authorization: Bearer #{response["access_token"]}"`)

for activity in activities do
  unless external_id = activity["external_id"]
    external_id = ""
  end
  
  filename = "#{File.basename(external_id, ".*")}_#{activity["start_date"]}.gpx"
  raise "file #{filename} exists allready" if File.exists?(filename)

  stream = JSON.parse(`curl -G https://www.strava.com/api/v3/activities/#{activity["id"]}/streams/latlng,altitude,time -H "Authorization: Bearer #{response["access_token"]}"`)
  
  latlng   = stream.map{ |entry| entry["data"] if entry["type"] == "latlng" }.compact.flatten(1).each_with_index.map{ |value, index| [index, value] }.collect{|index, a| {:index => index, :lat => a[0], :lng => a[1]}}
  altitude = stream.map{ |entry| entry["data"] if entry["type"] == "altitude" }.compact.flatten(1).each_with_index.map{ |value, index| [index, value] }.collect{|index, a| {:index => index, :altitude => a }}
  time     = stream.map{ |entry| entry["data"] if entry["type"] == "time" }.compact.flatten(1).each_with_index.map{ |value, index| [index, value] }.collect{|index, a| {:index => index, :time => a }}

  trackpoints = (latlng + altitude + time).group_by{|h| h[:index]}.map{|k,v| v.reduce(:merge)}

  gpx = Nokogiri::XML.parse('<gpx creator="StravaGPX" version="1.1" xmlns="http://www.topografix.com/GPX/1/1" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.topografix.com/GPX/1/1 http://www.topografix.com/GPX/1/1/gpx.xsd http://www.garmin.com/xmlschemas/GpxExtensions/v3 http://www.garmin.com/xmlschemas/GpxExtensionsv3.xsd http://www.garmin.com/xmlschemas/TrackPointExtension/v1 http://www.garmin.com/xmlschemas/TrackPointExtensionv1.xsd http://www.garmin.com/xmlschemas/GpxExtensions/v3 http://www.garmin.com/xmlschemas/GpxExtensionsv3.xsd http://www.garmin.com/xmlschemas/TrackPointExtension/v1 http://www.garmin.com/xmlschemas/TrackPointExtensionv1.xsd http://www.garmin.com/xmlschemas/GpxExtensions/v3 http://www.garmin.com/xmlschemas/GpxExtensionsv3.xsd http://www.garmin.com/xmlschemas/TrackPointExtension/v1 http://www.garmin.com/xmlschemas/TrackPointExtensionv1.xsd http://www.garmin.com/xmlschemas/GpxExtensions/v3 http://www.garmin.com/xmlschemas/GpxExtensionsv3.xsd http://www.garmin.com/xmlschemas/TrackPointExtension/v1 http://www.garmin.com/xmlschemas/TrackPointExtensionv1.xsd http://www.garmin.com/xmlschemas/GpxExtensions/v3 http://www.garmin.com/xmlschemas/GpxExtensionsv3.xsd http://www.garmin.com/xmlschemas/TrackPointExtension/v1 http://www.garmin.com/xmlschemas/TrackPointExtensionv1.xsd http://www.garmin.com/xmlschemas/GpxExtensions/v3 http://www.garmin.com/xmlschemas/GpxExtensionsv3.xsd http://www.garmin.com/xmlschemas/TrackPointExtension/v1 http://www.garmin.com/xmlschemas/TrackPointExtensionv1.xsd http://www.garmin.com/xmlschemas/GpxExtensions/v3 http://www.garmin.com/xmlschemas/GpxExtensionsv3.xsd http://www.garmin.com/xmlschemas/TrackPointExtension/v1 http://www.garmin.com/xmlschemas/TrackPointExtensionv1.xsd http://www.garmin.com/xmlschemas/GpxExtensions/v3 http://www.garmin.com/xmlschemas/GpxExtensionsv3.xsd http://www.garmin.com/xmlschemas/TrackPointExtension/v1 http://www.garmin.com/xmlschemas/TrackPointExtensionv1.xsd"><trk><name>' + activity["name"] + '</name><trkseg></trkseg></trk></gpx>')

  trkseg = gpx.at_xpath("//*[local-name() = 'trkseg']")
  
  c = 0
  for trkpt in trackpoints do
    trkseg << "<trkpt lat=\"#{trkpt[:lat]}\" lon=\"#{trkpt[:lng]}\"><ele>#{trkpt[:altitude]}</ele></trkpt>"
    c += 1
  end

  File.open(filename, "w") {|f| f.write(gpx)}
end

