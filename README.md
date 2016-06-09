# Orangetheses

[![Circle CI](https://circleci.com/gh/pulibrary/orangetheses.svg?style=svg)](https://circleci.com/gh/pulibrary/orangetheses)

Lightweight indexer for PUL non-MARC records.

## Installation

    $ gem install orangetheses

## Usage

```
# index PUL Senior theses fetched from DSpace REST Service
rake orangetheses:index_all SOLR="http://127.0.0.1:8983/solr/blacklight-core"

# fetch theses from DSpace and store Solr JSON docs in a file
rake orangetheses:cache_theses FILEPATH=/tmp/theses.json

# index Visuals data
rake orangetheses:index_visuals SOLR="http://127.0.0.1:8983/solr/blacklight-core"
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/pulibrary/orangetheses.
