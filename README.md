# SquashMatrix

Ruby SDK for www.squashmatrix.com

The generated client interacts with www.squashmatrix.com by retrieving player and club information and performing search requests.

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
client = SquashMatrix::Client.new # initialize client
=> SquashMatrix::Client
client.player_info(42547) # retrieve player info for joshua wilkosz #42547
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
client.club_info(336) # retrieve club info for melbourne university #336
=> {
  :name=>"Melbourne University Squash Club",
  :players=>[
    {
      :name=>"David Clegg",
      :rating=>342.5,
      :rank=>0,
      :id=>"43076"
    }
  ],
  :juniors=>[
    {
      :name=>"Trevor Bryden",
      :rating=>95.28,
      :rank=>0,
      :id=>"72728"
    }
  ]
}
client.search("joshua") # search for 'joshua'
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
client.search("melbourne") # search for 'melbourne'
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
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

To run tests, run `bundle exec rspec`

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/wilkosz/squash_matrix. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the SquashMatrix project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/wilkosz/squash_matrix/blob/master/CODE_OF_CONDUCT.md).
