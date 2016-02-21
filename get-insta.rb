# coding: utf-8

# TODO:rubyの例外処理を調べてなんとかする

require 'open-uri'
require 'uri'
require 'net/http'
require 'FileUtils'
require 'json'

class GetInsta

  def initialize(access_token)
    @access_token = access_token
  end

  def get_all_images(user_name, dirpath)
    user_id = user_id(user_name) #rubyでは変数名とメソッド名が同名の場合ローカル変数名が優先
    media_count = media_count(user_id)
    max_id = ""

    media_count.times do # TODO:media数だけ毎回リクエストを送るのは効率が悪い気がする
      uri = URI.parse("https://api.instagram.com/v1/users/#{user_id}/media/recent?access_token=#{@access_token}&count=1&max_id=#{max_id}")
      json = Net::HTTP.get(uri)
      result = JSON.parse(json)
      data = result["data"]
      data.each do |d|
        images = d["images"]
        image = images["standard_resolution"]
        image_url = image["url"].split("?")[0]
        save_image(image_url, dirpath)
        max_id = d["id"]
      end
    end
    puts "Done!"
  end

  def user_id(user_name)
    uri = URI.parse("https://api.instagram.com/v1/users/search?q=#{user_name}&access_token=#{@access_token}")
    json = Net::HTTP.get(uri)
    result = JSON.parse(json)
    data = result["data"]
    data.each do |d|
      if d["username"] == user_name
        return d["id"]
      end
    end
    return nil # TODO:ユーザーが見つからなかった場合返すのはnilで良いのかいい方法を調べる
  end
  
  def media_count(user_id)
    uri = URI.parse("https://api.instagram.com/v1/users/#{user_id}/?access_token=#{@access_token}")
    json = Net::HTTP.get(uri)
    result = JSON.parse(json)
    data = result["data"]
    counts = data["counts"]
    media_count = counts["media"]
  end

  def save_image(url, dirpath)
    filename = File.basename(url)
    filepath = dirpath + filename
    open(filepath, 'wb') do |output|
      open(url) do |data|
        output.write(data.read)
      end
    end
  end
end

access_token = ENV["INSTAGRAM_ACCESS_TOKEN"]

gi = GetInsta.new(access_token)

user_name = ARGV[0]
dir = ARGV[1]

gi.get_all_images(user_name, dir)
