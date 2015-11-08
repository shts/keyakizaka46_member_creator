# URLにアクセスするためのライブラリを読み込む
require 'open-uri'

# HTMLをパースするためのライブラリを読み込む
require 'nokogiri'

# Parseライブラリの読み込み
require 'parse-ruby-client'

# TODO: Windowsのみで発生する証明書問題によりSSL認証エラーの暫定回避策
#ENV['SSL_CERT_FILE'] = File.expand_path('C:\rumix\ruby\2.1\i386-mingw32\lib\ruby\2.1.0\rubygems\ssl_certs\cert.pem')

# Parseライブラリの初期化
Parse.init :application_id => ENV['PARSE_APP_ID'],
           :api_key        => ENV['PARSE_API_KEY']

BaseUrl = "http://www.keyakizaka46.com"
def fetch

  doc = Nokogiri::HTML(open(BaseUrl))
  doc.css('div#member').css('div.popup_win').each do |member|
    data = { :name_sub => nil,
             :name_main => nil,
             :image_url => nil,
             :birthday => nil,
             :bloodtype => nil,
             :constellation => nil,
             :height => nil
    }
    data[:name_sub] = member.css('p.popup_title_en').text
    data[:name_main] = member.css('p.popup_title').text
    data[:image_url] = BaseUrl + "/#{member.css('div.popup_img').css('img').first[:src]}"
    counter = 0
    member.css('div.popup_detail').css('dl').css('dd').each do |child|
      if counter == 0 then
        data[:birthday] = child.text.gsub("年", "/").gsub("月", "/").gsub("日", "")
      elsif counter == 1
        data[:bloodtype] = child.text
      elsif counter == 2
        data[:constellation] = child.text
      elsif counter == 3
        data[:birthplace] = child.text
      elsif counter == 4
        data[:height] = child.text
      end
      counter = counter + 1
    end
    yield(data) if block_given?
  end

end

fetch { |data|
  query = Parse::Query.new("Member").eq("image_url", data[:image_url])
  member = query.get.first
  if member == nil then
    new_member = Parse::Object.new("Member")
    data.each { |key, val|
      new_member[key] = val
    }
    puts new_member.save
  else
    puts "already registration"
  end
}
