require 'nokogiri'

module SquashMatrix
  class NokogiriParser
    def self.player_info(body)
      Nokogiri::HTML(body)&.xpath('//table[@id="results"]//tbody//tr')&.map do |r|
        date = r.at_css('td[1]')&.content
        opponent_id = r.at_css('td[10]//a')&.attribute('href')&.content
        match_id = r.at_css('td[12]//a')&.attribute('href')&.content
        rtn = {
          event: r.at_css('td[2]')&.content,
          division: r.at_css('td[3]')&.content,
          round: r.at_css('td[4]')&.content,
          position: r.at_css('td[5]')&.content,
          games: r.at_css('td[6]')&.content,
          points: r.at_css('td[7]')&.content,
          rating_adjustment: r.at_css('td[8]')&.content,
          rating: r.at_css('td[9]')&.content,
          opponent_rating: r.at_css('td[11]')&.content
        }
        rtn[:date] = Date.parse(date) if date
        rtn[:opponent_id] = /\/Home\/Player\/(.*)/.match(opponent_id)[1] if opponent_id
        rtn[:match_id] = /\/Home\/Match\/(.*)/.match(match_id)[1] if match_id
        rtn.values.any?(&:nil?) ? nil : rtn
      end.compact
    end

    def self.log_on_error(body)
      Nokogiri::HTML(body)&.xpath('//div[@class="validation-summary-errors"]//ul//li')&.map(&:content)
    end
  end
end
