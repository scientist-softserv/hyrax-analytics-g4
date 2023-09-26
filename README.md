# Hyrax::Analytics::G4

The `Hyrax::Analytics::G4` gem is intended to replace the current Google Analytics version 3 implementation of Hyrax; defined by the Legato interface.

As of <2023-09-25 Mon> this is being built as prototype to explore the G4 interface and beging building the corresponding queries to provide feature parity with the past implementation.

In conversations with the Hyrax tech lead and those at SoftServ by Scientist.com, we had two options:

1. Update Legato, based on the remaining steps identified in https://github.com/tpitale/legato/pull/141
2. Leverage Google’s [google-analytics-data](https://rubygems.org/gems/google-analytics-data) directly

The decision was to pursue Google’s provided gem, as that likely creates one less gem that we’d need to own.  Interestingly, in separating this out as it’s own gem, that decision may require revisitation.

Regardless, this is our place to explore that functionality.

## Installation

TODO: Something something `bundle install`.

## Usage

TODO: Write usage instructions here.

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

### Querying Data

You’ll need analytics data credentials; this is a JSON file available in the Google Analytics Profile.  Copy that to the `./config/analytics.json`.

You’ll need to add the path to that file to your ENV: (e.g. `export ANALYTICS_DATA_CREDENTIALS=./config/analytics.json`).  This is created on the https://console.cloud.google.com/apis/credentials page.

- You’ll need to select a project
- Then create/edit a service account
- Then choose the Keys tab within the service account
- Finally click Add Key

That will prompt you to download a JSON file.

As of <2023-09-25 Mon>, I run the following between each change:

- `bin/console` :: Boot up the bundler environment.
- `Report.call` :: A quick alias for querying the analytics.

I have not yet successfully retrieved any data, but that might be because there’s some configuration issue.


## Contributing

TODO: Something something submit issues/pull requests.
