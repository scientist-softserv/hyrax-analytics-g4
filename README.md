# Hyrax::Analytics::G4

The `Hyrax::Analytics::G4` gem is intended to replace the current Google Analytics version 3 implementation of Hyrax; defined by the Legato interface.  The module is named such that it could be discovered / leveraged in the [Hyrax::Analytics module](https://github.com/samvera/hyrax/blob/f14958e665535be2696dc1cdf9e205d6fc54e668/app/services/hyrax/analytics.rb).

As of <2023-09-25 Mon> this is being built as prototype to explore the G4 interface and beging building the corresponding queries to provide feature parity with the past implementation.  As of <2023-09-27 Wed> this gem has shifted as a means to fetch the Google Analytics information via the G4 API and then write that information to the Hyrax::CounterMetric model.  It's focus is on exposing metrics via the [SUSHI counter metrics developed for Palni/Palci](https://github.com/scientist-softserv/palni-palci/blob/6e8793dacd37759ef2166aa3854c1c6b169ae78e/app/models/sushi.rb).

In conversations with the Hyrax tech lead and those at SoftServ by Scientist.com, we had two options:

1. Update Legato, based on the remaining steps identified in https://github.com/tpitale/legato/pull/141
2. Leverage Google’s [google-analytics-data](https://rubygems.org/gems/google-analytics-data) directly

The decision was to pursue Google’s provided gem, as that likely creates one less gem that we’d need to own.  Interestingly, in separating this out as it’s own gem, that decision may require revisitation.

Regardless, this is our place to explore that functionality.

## Installation

Add to you `Gemfile`:

```ruby
gem "hyrax-analytics-g4", github: "scientist-softserv/hyrax-analytics-g4"
```


## Usage

There are a few points of configuration:

1. The [Hyrax::Analytics::G4::Configuration](./lib/hyrax/analytics/g4/configuration.rb), which has an example configuration in [Hyrax::Analytics::G4.config](./lib/hyrax/analytics/g4.rb)
2. Various `class_attributes` declared throughout the application (for less "public" but still valid configuration)

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

### But Where are My Tests?

I hear you, I really do.  The challenge I've been facing is multi-fold:

1. I need valid analytics data (which I have access to in my command-line testing)
2. We want this available for both Hyku applications and as part of Hyrax.  And in the specific client case, the Hyku application is behind in versions from the Hyrax latest release.
3. We have each Hyrax and Hyku application possibly having different SOLR schemas for the data.
4. As of yet, applications don't expose the Google Analytics Property ID (not the string for JS analytics nor anything in the secrets but something different).
5. Were I to install this locally, I need to seriously have works that are part of the analytics.

So instead, I started down the path of writing to the various object interfaces and documenting to the best of my ability.

Rest assured, however, that there is a means for testing much of the interfaces:

- `bin/test` will call the live Google Analytics as configured.
- `FAKE=t bin/test` will generate arbitrary analytics data.
  - When using the fake environment you can provide valid page paths via [Hyrax::Analytics::G4::RemoteDailyReport::Fake.page_path_generator](./lib/hyrax/analytics/g4/remote_daily_report.rb); by default this are quite arbitrary.

### Querying Data

You’ll need analytics data credentials; this is a JSON file available in the Google Analytics Profile.  Copy that to the `./config/analytics.json`.

You’ll need to add the path to that file to your ENV: (e.g. `export ANALYTICS_DATA_CREDENTIALS=./config/analytics.json`).  This is created on the https://console.cloud.google.com/apis/credentials page.

- You’ll need to select a project
- Then create/edit a service account
- Then choose the Keys tab within the service account
- Finally click Add Key

That will prompt you to download a JSON file.

I have not yet successfully retrieved any data, but that might be because there’s some configuration issue.


## Contributing

TODO: Something something submit issues/pull requests.
