require 'csv'
require 'google/apis/civicinfo_v2'
puts 'Event Manager Initialized!'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

private

def query_civic_api(zipcode)
  api_key = 'AIzaSyDz8QHB90XF6lme-XZYHmmUaGL_IQ57Ttk'
  civic_api = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_api.key = api_key
  begin
    response = civic_api.representative_info_by_address(address: zipcode, levels: 'country', 
                                                        roles: ['legislatorUpperBody', 'legislatorLowerBody'])
    response.officials.map(&:name).join(', ')
  rescue
    'You can find representatives by googling it, duh.'
  end
end

file_name = 'event_attendees.csv'
if File.exist?(file_name)
  reader = CSV.open(
    file_name,
    headers: true,
    header_converters: :symbol
  )
end

until reader.eof?
  contents = reader.readline
  contents[:zipcode] = clean_zipcode(contents[:zipcode])
  representative = query_civic_api(contents[:zipcode])
  p [contents[:first_name], contents[:zipcode], representative]
end
