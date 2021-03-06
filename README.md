# LedgerSync

[![Build Status](https://travis-ci.org/LedgerSync/ledger_sync.svg?branch=master)](https://travis-ci.org/LedgerSync/ledger_sync)
[![Gem Version](https://badge.fury.io/rb/ledger_sync.svg)](https://badge.fury.io/rb/ledger_sync)
[![Coverage Status](https://coveralls.io/repos/github/LedgerSync/ledger_sync/badge.svg?branch=master)](https://coveralls.io/github/LedgerSync/ledger_sync?branch=master)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'ledger_sync'
```

And then execute:

```bash
$ bundle
```

Or install it yourself as:

```bash
$ gem install ledger_sync
```

## Usage

To use LedgerSync, you must create an `Operation`.  The operation will be ledger-specific and will require the following:

1. Adaptor
2. Resource(s)

The code may look like the following:

```ruby
# First we create an adaptor, which is our connection to a ledger.
# Each ledger may require different keys, so check the
# documentation below for specifics.
adaptor = LedgerSync::Adaptors::QuickBooksOnline::Adaptor.new(
  access_token: access_token, # assuming this is defined
  client_id: ENV['QUICKBOOKS_ONLINE_CLIENT_ID'],
  client_secret: ENV['QUICKBOOKS_ONLINE_CLIENT_SECRET'],
  realm_id: ENV['QUICKBOOKS_ONLINE_REALM_ID'],
  refresh_token: refresh_token, # assuming this is defined
)

# Create a resource on which to operate.  Some resources have
# relationships with other resources.  You can use
# `Util::ResourcesBuilder` to create resources and relationships from
# a structured hash.
resource = LedgerSync::Customer.new(
  name: 'Sample Customer',
  email: 'test@example.com'
)

# Create the operation we want to perform.
operation = LedgerSync::Adaptors::QuickBooksOnline::Customer::Operations::Create.new(
  adaptor: adaptor,
  resource: resource
)

result = operation.perform # Returns a LedgerSync::OperationResult

if result.success?
  resource = result.operation.resource
  # Do something with resource
else # result.failure?
  raise result.error
end

# Because QuickBooks Online uses Oauth 2, you must always be sure to
# save the access_token, refresh_token, and expirations as they can
# change with any API call.
result.operation.adaptor.ledger_attributes_to_save.each do |key, value|
  # save values
end
```

## How it Works

### The Library Structure

This library consists of two important layers:

1. Resources
2. Adaptors

#### Resources

Resources are named ruby objects (e.g. `Customer`, `Payment`, etc.) with strict attributes (e.g. `name`, `amount`, etc.).  They are a layer between your application and an adaptor.  They can be validated using an adaptor.  You can create and use the resources, and an adaptor will update resources as needed based on the intention and outcome of that operation.

You can find supported resources by calling `LedgerSync.resources`.

Resources have defined attributes.  Attributes are explicitly defined.  An error is thrown if an unknown attribute is passed to it.  You can retrieve the attributes of a resource by calling `LedgerSync::Customer.attributes`.

A subset of these `attributes` may be a `reference`, which is simply a special type of attribute that references another resource.  You can retrieve the references of a resource by calling `LedgerSync::Customer.references`.

### Adaptors

Adaptors are ledger-specific ruby objects that contain all the logic to authenticate to a ledger, perform ledger-specific operations, and validate resources based on the requirements of the ledger.  Adaptors contain a number of useful objects:

- adaptor
- operations
- searchers

#### Adaptor

The adaptor handles authentication and requests to the ledger.  Each adaptors initializer will vary based on the needs of that ledger.

#### Operation

Each adaptor defines operations that can be performed on specific resources (e.g. `Customer::Operations::Update`, `Payment::Operations::Create`).  The operation defines two key things:

- a `Contract` class which is used to validate the resource using the `dry-validation` gem
- a `perform` instance method, which handles the actual API requests and response/error handling.

Note: Adaptors may support different operations for each resource type.

#### Searcher

Searchers are used to search objects in the ledger.  A searcher takes an `adaptor`, `query` string and optional `pagination` hash.  For example, to search customer's by name:

```ruby
searcher = LedgerSync::Adaptors::QuickBooksOnline::Customer::Searcher.new(
  adaptor: adaptor # assuming this is defined,
  query: 'test'
)

result = searcher.search # returns a LedgerSync::SearchResult

if result.success?
  resources = result.resources
  # Do something with found resources
else # result.failure?
  raise result.error
end

# Different ledgers may use different pagination strategies.  In order
# to get the next and previous set of results, you can use the following:
next_searcher = searcher.next_searcher
previous_searcher = searcher.previous_searcher
```

## NetSuite

The NetSuite adaptor leverages NetSuite's REST API.

### Resource Metadata and Schemas

Due to NetSuites granular user permissions and custom attributes, resources and methods for those resources can vary from one user (a.k.a. token) to another.  Because of this variance, there are some helper classes that allow you to retrieve NetSuite records, allowed methods, attributes/parameters, etc.

To retrieve the metadata for a record:

```ruby
metadata = LedgerSync::Adaptors::NetSuite::Record::Metadata.new(
  adaptor: netsuite_adaptor, # Assuming this is previous defined
  record: :customer
)

puts metadata.http_methods # Returns a list of LedgerSync::Adaptors::NetSuite::Record::HTTPMethod objects
puts metadata.properties # Returns a list of LedgerSync::Adaptors::NetSuite::Record::Property objects
```

### Reference

- [NetSuite REST API Documentation](https://docs.oracle.com/cloud/latest/netsuitecs_gs/NSTRW/NSTRW.pdf)

## NetSuite SOAP

LedgerSync supports the NetSuite SOAP adaptor, leveraging [the NetSuite gem](https://github.com/NetSweet/netsuite).  The adaptor and sample operations are provided, though the main NetSuite adaptor uses the REST API.

### Reference

- [NetSuite SOAP API Documentation](https://docs.oracle.com/cloud/latest/netsuitecs_gs/NSTWR/NSTWR.pdf)


## QuickBooks Online

### OAuth

QuickBooks Online utilizes OAuth 2.0, which requires frequent refreshing of the access token.  The adaptor will handle this automatically, attempting a single token refresh on any single request authentication failure.  Depending on how you use the library, every adaptor has implements a class method `ledger_attributes_to_save`, which is an array of attributes that may change as the adaptor is used.  You can also call the instance method `ledger_attributes_to_save` which will be a hash of these values.  It is a good practice to always store these attributes if you are saving access tokens in your database.

The adaptor also implements some helper methods for getting tokens.  For example, you can set up an adaptor using the following:

```ruby
# Retrieve the following values from Intuit app settings
client_id     = 'ID'
client_secret = 'SECRET'
redirect_uri  = 'http://localhost:3000'

oauth_client = LedgerSync::Adaptors::QuickBooksOnline::OAuthClientHelper.new(
  client_id: client_id,
  client_secret: client_secret
)

puts oauth_client.authorization_url(redirect_uri: redirect_uri)

# Visit on the output URL and authorize a company.
# You will be redirected back to the redirect_uri.
# Copy the full url from your browser:

uri = 'https://localhost:3000/?code=FOO&state=BAR&realm_id=BAZ'

adaptor = LedgerSync::Adaptors::QuickBooksOnline::Adaptor.new_from_oauth_client_uri(
  oauth_client: oauth_client,
  uri: uri
)

# You can test that the auth works:

adaptor.refresh!
```

**Note: If you have a `.env` file storing your secrets, the adaptor will automatically update the variables and record previous values whenever values change**

### Webhooks

Reference: [QuickBooks Online Webhook Documentation](https://developer.intuit.com/app/developer/qbo/docs/develop/webhooks/managing-webhooks-notifications#validating-the-notification)

LedgerSync offers an easy way to validate and parse webhook payloads.  It also allows you to easily fetch the resources referenced.  You can create and use a webhook with the following:

```ruby
# Assuming `request` is the webhook request received from Quickbooks Online
webhook = LedgerSync::Adaptors::QuickBooksOnline::Webhook.new(
  payload: request.body.read # It accepts a JSON string or hash
)

verification_token = WEBHOOK_VERIFICATION_TOKEN # You get this token when you create webhooks in the QuickBooks Online dashboard
signature = request.headers['intuit-signature']
raise 'Not valid' unless webhook.valid?(signature: signature, verification_token: verification_token)

# Although not yet used, webhooks may include notifications for multiple realms
webhook.notifications.each do |notification|
  puts notification.realm_id

  # Multiple events may be referenced.
  notification.events.each do |event|
    puts event.resource # Returns a LedgerSync resource with the `ledger_id` set

    # Other helpful methods
    notification.find_operation_class(adaptor: your_quickbooks_adaptor_instance) # The respective Find class
    notification.find_operation(adaptor: your_quickbooks_adaptor_instance) # The initialized respective Find operation
    notification.find(adaptor: your_quickbooks_adaptor_instance) # Performs a Find operation for the resource retrieving the latest version from QuickBooks Online
  end

  # Other helpful methods
  notification.resources # All resources for a given webhook across all events
end

# Other helpful methods
webhook.events # All events for a given webhook across all realms
webhook.resources # All events for a given webhook across all realms and events
```

### Errors

- [QuickBooks Online Error Documentation](https://developer.intuit.com/app/developer/qbo/docs/develop/troubleshooting/error-codes)

## Tips and More

### Keyword Arguments

LedgerSync heavily uses ruby keyword arguments so as to make it clear what values are being passed and which attributes are required.  When this README says something like "the `fun_function` function takes the argument `foo`" that translates to `fun_function(foo: :some_value)`.

### Fingerprints

Most objects in LedgerSync can be fingerprinted by calling the instance method `fingerprint`.  For example:

```ruby
puts LedgerSync::Customer.new.fingerprint # "b3eab7ec00431a4ae0468fee72e5ba8f"

puts LedgerSync::Customer.new.fingerprint == LedgerSync::Customer.new.fingerprint # true
puts LedgerSync::Customer.new.fingerprint == LedgerSync::Customer.new(name: :foo).fingerprint # false
puts LedgerSync::Customer.new.fingerprint == LedgerSync::Payment.new.fingerprint # false
```

Fingerprints are used to compare objects.  This method is used in de-duping objects, as it only considers the data inside and not the instance itself (as shown above).

### Serialization

Most objects in LedgerSync can be serialized by calling the instance method `serialize`.  For example:

```ruby
puts LedgerSync::Payment.new(
  customer: LedgerSync::Customer.new
)

{
  root: "LedgerSync::Payment/8eed81c0177801a001f2544f0c85e21d",
  objects: {
    "LedgerSync::Payment/8eed81c0177801a001f2544f0c85e21d": {
      id: "LedgerSync::Payment/8eed81c0177801a001f2544f0c85e21d",
      object: "LedgerSync::Payment",
      fingeprint: "8eed81c0177801a001f2544f0c85e21d",
      data: {
        currency: nil,
        amount: nil,
        customer: {
          object: "reference",
          id: "LedgerSync::Customer/b3eab7ec00431a4ae0468fee72e5ba8f"
        },
        external_id: "",
        ledger_id: nil,

      }
    },
    "LedgerSync::Customer/b3eab7ec00431a4ae0468fee72e5ba8f": {
      id: "LedgerSync::Customer/b3eab7ec00431a4ae0468fee72e5ba8f",
      object: "LedgerSync::Customer",
      fingeprint: "b3eab7ec00431a4ae0468fee72e5ba8f",
      data: {
        name: nil,
        email: nil,
        phone_number: nil,
        external_id: "",
        ledger_id: nil
      }
    }
  }
}
```

The serialization of any object follows the same structure.  There is a `:root` key that holds the ID of the root object.  There is also an `:objects` hash that contains all of the objects for this serialization.  As you can see, unique nested objects listed in the `:objects` hash and referenced using a "reference object", in this case:

```ruby
{
  object: "reference",
  id: "LedgerSync::Customer/b3eab7ec00431a4ae0468fee72e5ba8f"
}
```

## Test Adaptor

LedgerSync offers a test adaptor `LedgerSync::Adaptors::Test::Adaptor` that you can easily use and stub without requiring API requests.  For example:

```ruby

operation = LedgerSync::Adaptors::Test::Customer::Operations::Create.new(
  adaptor: LedgerSync::Adaptors::Test::Adaptor.new,
  resource: LedgerSync::Customer.new(name: 'Test Customer')
)

expect(operation).to be_valid

result = operation.perform
expect(result).to be_a(LedgerSync::OperationResult::Success)
expect(result).to be_success

expect { operation.perform }.to raise_error(PerformedOperationError)
```

## Development

After checking out the repo, run `bin/setup` to install dependencies.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org)

### Testing

Run `bundle exec rspec` to run all unit, feature, and integration tests.  Unlike QA Tests, all external HTTP requests and responses are stubbed.

### QA Testing

**BE SURE TO USE A TEST ENVIRONMENT ON YOUR LEDGER.**

To fully test the library against the actual ledgers, you can run `bin/qa` which will run all tests in the `qa/` directory.  QA Tests are written in RSpec.  Unlike tests in the `spec/` directory, QA tests allow external HTTP requests.

As these interact with real ledgers, you will need to provide secrets.  You can do so in a `.env` file in the root directory.  Copy the `.env.template` file to get started.

**WARNINGS:**

- **BE SURE TO USE A TEST ENVIRONMENT ON YOUR LEDGER.**
- **NEVER CHECK IN YOUR SECRETS (e.g. the `.env` file).**
- Because these tests actually create and modify resources, they attempt to do "cleanup" by deleting any newly created resources.  This process could fail, and you may need to delete these resources manually.

### Console

Run `bundle console` to start and interactive console with the library already loaded. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

## Deployment

To deploy a new version of the gem to RubyGems, you can use the `release.sh` script in the root.  The script takes advantage of [the bump gem](https://github.com/gregorym/bump).  So you may call the script using any of the following:

```bash
# Version Format: MAJOR.MINOR.PATCH
./release.sh patch # to bump X in 1.1.X
./release.sh minor # to bump X in 1.X.1
./release.sh major # to bump X in X.1.1
```

### Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/LedgerSync/ledger_sync. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

### License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

### Code of Conduct

Everyone interacting in the LedgerSync project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/LedgerSync/ledger_sync/blob/master/CODE_OF_CONDUCT.md).

# Maintainers

A big thank you to our maintainers:

- [@ryanwjackson](https://github.com/ryanwjackson)
- [@jozefvaclavik](https://github.com/jozefvaclavik)
- And the whole [Modern Treasury](https://www.moderntreasury.com) team