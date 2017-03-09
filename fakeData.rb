require 'byebug'
require 'open-uri'
require 'pp'
require 'nokogiri'
require 'progress_bar'
require 'json'
require 'algoliasearch'
require 'faker'
require 'csv'
require 'geocoder'
require 'geokit-rails'
require 'random-location'

Geokit::Geocoders::GoogleGeocoder.api_key = 'AIzaSyCsIqcSYWP8UgPC0e_xsN3_s_YJgiRlyEc'

def random_city
  num = rand(5)
  if num == 0
    return RandomLocation.near_by(37.7749, -122.4194, 10000) #SF
  elsif num == 2
    return RandomLocation.near_by(40.7128, -74.0059, 10000) #NY
  elsif num == 3
    return RandomLocation.near_by(30.2672, -97.7431, 10000) #Austin
  elsif num == 4
    return RandomLocation.near_by(41.8781, -87.6298, 10000) #Chicago
  else
    return RandomLocation.near_by(25.7617, -80.1918, 10000) #Miami
  end
end

def random_category
  num = rand(5)
  if num == 0
    return "CINEMA CAMERAS"
  elsif num == 2
    return "STILL / HYBRID CAMERAS"
  elsif num == 3
    return "CINEMA LENSES" #Austin
  elsif num == 4
    return "STILL LENSES"
  else
    return "VIRTUAL REALITY & NEW TECH"
  end
end

def calendar
  limit = 1000
  cal = []
  for i in 0..limit
    date = Date.today + i
    free = rand(10) % 4 == 0
    if free
      cal << (Date.today + i).to_s
    end
  end
  cal
end



def fake_product
  loc = random_city
  res=Geokit::Geocoders::GoogleGeocoder.reverse_geocode( loc)
  product = {}
  product['_geoloc'] = {
    lat: loc[0],
    lng: loc[0],
  }
  product['Price'] = rand(100)
  product["LastName"] = Faker::Name.last_name
  product["FirstName"] = Faker::Name.first_name
  product["LensType"] = Faker::Vehicle.manufacture
  product["Mount"] = Faker::StarWars.vehicle
  product["Brand"] = Faker::Vehicle.manufacture
  product["Category"] = random_category
  product["ProductName"] = Faker::StarWars.droid
  product['createdAt'] = Time.now.to_i
  product['views'] = rand(500)
  product['popularity'] = rand(500)
  product["image_url"] = "https://d1rzxhvrtciqq1.cloudfront.net/images/listing_images/images/58104/medium/44600d-67c54f-img_1938.jpg"
  product['unavaliable'] = calendar
  return product
end
limit = 50
bar = ProgressBar.new(limit)
products = []
for i in 0..limit
  bar.increment!
  products << fake_product
end

File.open("products_price.json","w") do |f|
  f.write(products.to_json)
end

Algolia.init :application_id => "C1GEL7N07Y", :api_key => "0175dae427cdeeb9e978947f6b5174a9"
index = Algolia::Index.new("products")
index.set_settings( { "customRanking"            => ["desc(popularity)", "desc(views)"],
                      "searchableAttributes"     => ["ProductName", "Category", "Brand", "Mount"],
                      "attributesToHighlight"    => ["ProductName", "Category", "Brand", "Mount"],
                      "attributesForFaceting"    => ["Category", "Brand", "Mount", "LensType", "unavaliable"]},
                    {"forwardToReplicas"        => true})
index.clear_index
index.add_objects(products)
