# SquashMatrix

Ruby SDK for www.squashmatrix.com

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'squash_matrix'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install squash_matrix

## Usage

```ruby
client = SquashMatrix::Client.new(player: 42547, password: "foo")# initialize client
=> SquashMatrix::Client
client.get_player_info(42547) # retrieve player info for joshua wilkosz #42547
=> {
  :name =>"Joshua Wilkosz"
  :rating=>"250.202",
  :clubs=>[
    {
      :name=>"Melbourne University (2011-2017)",
      :id=>336
    }
  ],
  :teams=>[
    {
      :name=>"Melbourne University (2) (2017)",
      :id=>72831
    }
  ]
}
client.get_player_results(42547) # retrieve player results for joshua wilkosz #42547
=> [
  {
    :event=>"2017 Melbourne Autumn  State Open Pennant",
    :division=>"State 2",
    :round=>"7",
    :position=>"3",
    :games=>"2-3",
    :points=>"67-73",
    :rating_adjustment=>0.58,
    :rating=>250.2,
    :opponent_rating=>275.24,
    :opponent_name=>"David Crossley",
    :date=> Time,
    :opponent_id=>26809,
    :match_id=>1003302
  }
]
client.get_club_info(336) # retrieve club info for melbourne university #336
=> {
  :name=>"Melbourne University Squash Club",
  :players=>[
    {
      :name=>"David Clegg",
      :rating=>342.5,
      :rank=>0,
      :id=>43076
    }
  ],
  :juniors=>[
    {
      :name=>"Trevor Bryden",
      :rating=>95.28,
      :rank=>0,
      :id=>72728
    }
  ]
}
client.get_search_results("joshua") # search results for 'joshua'
=> {
  :players=>[
    {
      :name=>"Joshua Altmann",
      :club_name=>"Monash University",
      :id=>47508,
      :rating=>107.821
    }
  ],
  :teams=>[
    {
      :name=>"Joshua mallison",
      :division_name=>"Box 08",
      :event_name=>"2017 Briars @ Thornleigh Box Challenge (Season 29)",
      :id=>80792
    }
  ],
  :clubs=>[]
}
client.get_search_results("melbourne") # search results for 'melbourne'
=> {
  :players=>[
    {
      :name=>"Melbourne Simpson",
      :club_name=>"Mirrabooka",
      :id=>17797,
      :rating=>199.607
    }
  ],
  :teams=>[
    {
      :name=>"Melbourne Uni (2)@Fitz",
      :division_name=>"C Reserve",
      :event_name=>"2012 Melbourne Spring SSL Women's Pennant",
      :id=>39605
    }
  ],
  :clubs=>[
    {
      :name=>"Melbourne University",
      :state=>"Victoria",
      :id=>336
    }
  ]
}
# saving authentication state or using multiple clients
p = client.get_save_params
p => {
  :player=>42547,
  :password=>"Foo",
  :suppress_errors=>false,  
  :user_agent=>"Mozilla/5.0 (Windows; U; Windows NT 6.1; en-US; rv:1.9.2.13) Gecko/20101213 Opera/9.80 (Windows NT 6.1; U; zh-tw) Presto/2.7.62 Version/11.01",
  :cookie=>".ASPXAUTH=CDA48BC54FCEB4F164D6AC464EFB3414866040FF085915F32BA18EFD5CF995DC59889B5E2124567CBE1B53DE66D6318E6510C5B884EAB5216457092AC079999C3E63BDDA45C94CCA1CD82E485A30D698BA426F4AA9C94301125966DB5D05FD4D; ASP.NET_SessionId=tx02u3xp51js1s3mgwwxhgq1; GroupId=0",
  :expires=>"2018-08-25 17:05:04 UTC"
}
replica_client = SquashMatrix::Client.new(p)
=> SquashMatrix::Client
# Don't want to use credentials, use a proxy instead
proxy_addr = '78.186.111.109'
proxy_port =  8080
client_behind_proxy = SquashMatrix::Client.new(proxy_addr: proxy_addr, proxy_port: proxy_port, proxy_custom_headers: {'X-Forwarded-For': proxy_addr}) # squash matrix tracks the X-Forwarded-For header, also depending on the proxy service you are using you may need to overwrite header params
begin
  (100..1000).each { |i| client_behind_proxy.get_club_info(336) }
rescue SquashMatrix::Errors::ForbiddenError => e
  puts "Time to change proxy address!"
end
```
*Note: in previous example `client` and `replica_client` authentication will expire at `2018-08-25 17:05:04 UTC` and make separate calls for re-authentication and thereafter will have separate instance states*

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

To run tests, run `bundle exec rspec`

## Contributing

Bug reports and pull requests are welcome on GitHub at <https://github.com/wilkosz/squash_matrix>. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the SquashMatrix project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/wilkosz/squash_matrix/blob/master/CODE_OF_CONDUCT.md).
