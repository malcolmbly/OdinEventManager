require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
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
    response.officials
  rescue
    'You can find representatives by googling it, duh.'
  end
end

def load_erb_template
  template_letter = File.read('form_letter.erb')
  ERB.new template_letter
end

def save_file(id)
  form_letter = load_erb_template.result(binding)
  Dir.mkdir('output') unless Dir.exist?('output')
  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

def read_csv(file_name)
  if File.exist?(file_name)
    reader = CSV.open(
      file_name,
      headers: true,
      header_converters: :symbol
    )
  end

  until reader.eof?
    contents = reader.readline
    id = contents[0]
    zipcode = clean_zipcode(contents[:zipcode])
    first_name = contents[:first_name]
    representatives = query_civic_api(contents[:zipcode])
    save_file(id)
  end
end

file_name = 'event_attendees.csv'
read_csv(file_name)
