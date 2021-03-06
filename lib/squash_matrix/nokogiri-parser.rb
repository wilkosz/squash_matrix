# frozen_string_literal: true

require 'nokogiri'
require_relative 'constants'

module SquashMatrix
  class NokogiriParser
    class << self
      def get_player_results(body)
        rtn = Nokogiri::HTML(body)&.xpath('//table[@id="results"]//tbody//tr')&.map do |r|
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
            rating_adjustment: r.at_css('td[8]')&.content&.to_f,
            rating: r.at_css('td[9]')&.content&.to_f,
            opponent_rating: r.at_css('td[11]')&.content&.to_f,
            opponent_name: r.at_css('td[10]//a')&.content
          }
          rtn[:date] = Date.parse(date) if date
          rtn[:opponent_id] = SquashMatrix::Constants::PLAYER_FROM_PATH_REGEX.match(opponent_id)[1].to_i if opponent_id
          rtn[:match_id] = SquashMatrix::Constants::MATCH_FROM_PATH_REGEX.match(match_id)[1].to_i if match_id
          rtn.values.any?(&:nil?) ? nil : rtn
        end
        rtn.compact
      end

      def get_player_info(body)
        bc = Nokogiri::HTML(body)&.xpath('//div[@id="bodycontent"]')
        name = bc.children[3].text
        rows = bc.xpath('//div[@id="Summary"]//table[@id="profile"]//tbody//tr')
        rating = rows[1]&.css('td[2]')&.text
        clubs = rows[2]&.css('td[2]')&.css('ul//li')&.map do |c|
          id = c&.css('a')&.attribute('href')&.text
          rtn = {
            name: c&.text
          }
          rtn[:id] = SquashMatrix::Constants::CLUB_FROM_PATH_REGEX.match(id)[1].to_i if id
          rtn
        end
        teams = rows[3]&.css('td[2]')&.css('ul//li')&.map do |c|
          id = c&.css('a')&.attribute('href')&.text
          rtn = {
            name: c&.text
          }
          rtn[:id] = SquashMatrix::Constants::TEAM_FROM_PATH_REGEX.match(id)[1].to_i if id
          rtn
        end
        {
          name: name,
          rating: rating,
          clubs: clubs,
          teams: teams
        }
      end

      def get_club_info(body)
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
          rtn[:id] = SquashMatrix::Constants::PLAYER_FROM_PATH_REGEX.match(player_path)[1].to_i if player_path
          rtn
        end
        juniors = html.xpath('//div[@id="Rankings"]//div[@class="columnside"]//table[@class="alternaterows"]//tbody//tr')&.map do |r|
          player_path = r.css('td[2]//a').attribute('href').value
          rank = r.css('td[1]').text
          rtn = {
            name: r.css('td[2]').text,
            rating: r.css('td[3]').text.to_f
          }
          rtn[:rank] = rank.to_i if rank
          rtn[:id] = SquashMatrix::Constants::PLAYER_FROM_PATH_REGEX.match(player_path)[1].to_i if player_path
          rtn
        end
        {
          name: name,
          players: players.compact,
          juniors: juniors.compact
        }
      end

      def get_search_results(body)
        bc = Nokogiri::HTML.parse(body).at_xpath('//div[@id="bodycontent"]')&.children
        return unless bc&.length
        rtn = {}
        bc&.each_with_index do |c, i|
          if c.name == 'h2'
            case c.text
            when 'Players'
              rtn[:players] = get_players_from_search_results(bc[i + 2]) if bc[i + 2].children.length
            when 'Teams'
              rtn[:teams] = get_teams_from_search_results(bc[i + 2]) if bc[i + 2].children.length
            when 'Clubs'
              rtn[:clubs] = get_clubs_from_search_results(bc[i + 2]) if bc[i + 2].children.length
            end
          end
        end
        rtn
      end

      def get_log_on_error(body)
        Nokogiri::HTML(body)&.xpath('//div[@class="validation-summary-errors"]//ul//li')&.map(&:content)
      end

      private

      def get_players_from_search_results(node)
        node.css('tbody//tr')&.map do |tr|
          id = tr.css('td[1]//a')&.attribute('href')&.value
          rating = tr.css('td[3]')&.text
          rtn = {
            name: tr.css('td[1]')&.text,
            club_name: tr.css('td[2]')&.text
          }
          rtn[:id] = SquashMatrix::Constants::PLAYER_FROM_PATH_REGEX.match(id)[1].to_i if id
          rtn[:rating] = rating.to_f if rating
          rtn
        end
      end

      def get_teams_from_search_results(node)
        node.css('tbody//tr')&.map do |tr|
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

      def get_clubs_from_search_results(node)
        node.css('tbody//tr')&.map do |tr|
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
end
