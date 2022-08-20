require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'time'
puts 'Event Manager Initialized!'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

def clean_phone_number(phone_number)
  phone_number.gsub!(/[^0-9]/, '')
  length = phone_number.length
  if length > 11 || length < 10
    ''
  elsif length == 11 && phone_number[0] != 1
    ''
  else
    phone_number[-10, length]
  end
end

def find_peak_hours(reader)
  reg_dates = Array.new(24, 0)
  until reader.eof?
    contents = reader.readline
    time = Time.strptime(contents[:regdate], '%m/%d/%Y %H:%M')
    hour = time.hour
    reg_dates[hour] += 1
  end
  p reg_dates
  reg_dates.each_with_index.max[1]
end

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

def save_file(id, form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')
  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

def read_csv(reader)
  until reader.eof?
    contents = reader.readline
    id = contents[0]
    zipcode = clean_zipcode(contents[:zipcode])
    first_name = contents[:first_name]
    representatives = query_civic_api(contents[:zipcode])
    form_letter = load_erb_template.result(binding)
    save_file(id, form_letter)
    # phone_number = clean_phone_number(contents[:homephone])
    # p phone_number
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
# read_csv(reader)
p find_peak_hours(reader)
