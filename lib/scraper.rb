require 'open-uri'
require 'nokogiri'
require 'date'
require 'json'

def scrap
  result = {}
  (1..3).each do |month_index|
    (1..1).each do |day_index|
      begin
        day, month = form_date(day_index, month_index)

        puts "Scraping #{month} #{day}..."

        description, events, births, deaths = extract_from(day, month)

        result["#{month}-#{day}".to_sym] = {
          description: description, events: events, births: births, deaths: deaths
        }
      rescue NoMethodError
        puts 'It seems this date does not have any episodes.'
      end
    end
  end

  export_to_file(result)
end

def form_date(day_index, month_index)
  date = Date._strptime("#{day_index}/#{month_index}", '%d/%m')
  [date[:mday], Date::MONTHNAMES[date[:mon]]]
end

def extract_from(day, month)
  html = Nokogiri::HTML open("https://bn.wikipedia.org/wiki/#{month}_#{day}")

  description = html.css('#mw-content-text p')
                    .map(&:text)
                    .find { |text| text.include?("জানুয়ারি") || text.include?("ফেব্রুয়ারি") || text.include?("মার্চ") }

  events = parse_ul html.css('#mw-content-text.mw-content-ltr ul')[1]
  births = parse_ul html.css('#mw-content-text.mw-content-ltr ul')[2]
  deaths = parse_ul html.css('#mw-content-text.mw-content-ltr ul')[3]

  [description, events, births, deaths]
end

def parse_ul(ul)
  ul.css('li').map do |li|
    year, *text = li.text.split(' – ')
    { year: year, data: text.join(' – ') }
  end
end

def export_to_file(hash_data)
  File.write('episodes_bn.json', hash_data.to_json)
  puts 'Results stored in episodes_bn.json'
end

scrap
