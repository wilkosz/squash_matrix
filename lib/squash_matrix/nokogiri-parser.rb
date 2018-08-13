require 'nokogiri'
require_relative 'constants'

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
          opponent_rating: r.at_css('td[11]')&.content,
          opponent_name: r.at_css('td[10]//a')&.content
        }
        rtn[:date] = Date.parse(date) if date
        rtn[:opponent_id] = SquashMatrix::Constants::PLAYER_FROM_PATH_REGEX.match(opponent_id)[1] if opponent_id
        rtn[:match_id] = SquashMatrix::Constants::MATCH_FROM_PATH_REGEX.match(match_id)[1] if match_id
        rtn.values.any?(&:nil?) ? nil : rtn
      end.compact
    end

    def self.club_info(body)
      html = Nokogiri::HTML(body)
      name = SquashMatrix::Constants::CLUB_FROM_TITLE_REGEX.match(html.css('title').text)[1]
      players = html.xpath('//div[@id="Rankings"]//div[@class="columnmain"]//table[@class="alternaterows"]//tbody//tr')&.map do |r|
        player_path = r.css('td[2]//a').attribute('href').value
        rank = r.css('td[1]').text
        rtn = {
          name: r.css('td[2]').text,
          rating: r.css('td[3]').text.to_f
        }
        rtn[:rank] = rank.to_i if rank
        rtn[:id] = SquashMatrix::Constants::PLAYER_FROM_PATH_REGEX.match(player_path)[1] if player_path
        rtn
      end.compact
      juniors = html.xpath('//div[@id="Rankings"]//div[@class="columnside"]//table[@class="alternaterows"]//tbody//tr')&.map do |r|
        player_path = r.css('td[2]//a').attribute('href').value
        rank = r.css('td[1]').text
        rtn = {
          name: r.css('td[2]').text,
          rating: r.css('td[3]').text.to_f
        }
        rtn[:rank] = rank.to_i if rank
        rtn[:id] = SquashMatrix::Constants::PLAYER_FROM_PATH_REGEX.match(player_path)[1] if player_path
        rtn
      end.compact
      {
        name: name,
        players: players,
        juniors: juniors
      }
    end

    def self.search_results(body)
      bc = Nokogiri::HTML.parse(body).at_xpath('//div[@id="bodycontent"]')&.children
      return unless bc&.length
      rtn = {}
      bc&.each_with_index do |c, i|
        if c.name == "h2"
          case c.text
          when "Players"
            rtn[:players] = players_from_search(bc[i+2]) if bc[i+2].children.length
          when "Teams"
            rtn[:teams] = teams_from_search(bc[i+2]) if bc[i+2].children.length
          when "Clubs"
            rtn[:clubs] = clubs_from_search(bc[i+2]) if bc[i+2].children.length
          end
        end
      end
      rtn
    end

    def self.log_on_error(body)
      Nokogiri::HTML(body)&.xpath('//div[@class="validation-summary-errors"]//ul//li')&.map(&:content)
    end

    def self.players_from_search(node)
      node.css('tbody').css('tr')&.map do |tr|
        id = tr.css('td[1]//a')&.attribute('href')&.value
        rating = tr.css('td[3]')&.text
        rtn = {
          name: tr.css('td[1]')&.text,
          club_name: tr.css('td[2]')&.text
        }
        rtn[:id] = SquashMatrix::Constants::PLAYER_FROM_PATH_REGEX.match(id)[1].to_i if id && !id.empty?
        rtn[:rating] = rating.to_f if rating
        rtn
      end
    end

    def self.teams_from_search(node)
      node.css('tbody').css('tr')&.map do |tr|
        id = tr.css('td[1]//a')&.attribute('href')&.value
        rtn = {
          name: tr.css('td[1]')&.text,
          division_name: tr.css('td[2]')&.text,
          event_name: tr.css('td[3]')&.text
        }
        rtn[:id] = SquashMatrix::Constants::TEAM_FROM_PATH_REGEX.match(id)[1].to_i if id
        rtn
      end
    end

    def self.clubs_from_search(node)
      node.css('tbody').css('tr')&.map do |tr|
        puts tr
        id = tr.css('td[1]//a')&.attribute('href')&.value
        rtn = {
          name: tr.css('td[1]')&.text,
          state: tr.css('td[2]')&.text
        }
        rtn[:id] = SquashMatrix::Constants::CLUB_FROM_PATH_REGEX.match(id)[1].to_i if id
        rtn
      end
    end
  end
end
