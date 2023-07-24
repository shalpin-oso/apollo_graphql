# data.rb

require 'sinatra'
require 'graphql'
require 'json'
require 'apollo-federation'
require 'webrick'

# Define your GraphQL schema
class BaseArgument < GraphQL::Schema::Argument
  include ApolloFederation::Argument
end

class BaseField < GraphQL::Schema::Field
  include ApolloFederation::Field

  argument_class BaseArgument
end

class BaseObject < GraphQL::Schema::Object
  include ApolloFederation::Object

  field_class BaseField
end
#
class ProductType < BaseObject
  include ApolloFederation::Object

  key fields: :id
  
  field :id, String, null: false
  field :name, String, null: false

  def self.resolve_reference(ref, _ctx)
    id = ref[:id]
    { id: id, name: "Mug number #{id}"}
  end
end

class ProductSearchByCriteriaBlob < BaseObject
  include ApolloFederation::Object

  key fields: :query
  field :query, String, null: false, external: false
  field :products, [ProductType], null: false, provides: { fields: :query }, external: true

  def products
    # This resolver function should only return the criteria field
    # The actual products will be fetched from the search_subgraph
    p { __typename: 'ProductSearchInput', query: object.query }
  end
end

class CampaignType < BaseObject
  include ApolloFederation::Object

  field :id, String, null: false
  field :name, String, null: false
  field :search_criteria, ProductSearchByCriteriaBlob, null: false
end

class QueryType < BaseObject
  include ApolloFederation::Object

  field :campaigns, [CampaignType], null: false

  def campaigns
    # Simulated logic to return a list of campaigns
    [
      { id: 1, name: "Microsoft Campaign", search_criteria: {query:'{"input":{"query":"mug"}}'}},
      { id: 2, name: "Google Campaign", search_criteria: {query:'{"input":{"query":"mug"}}'}}
    ]
  end
end

class MySchema < GraphQL::Schema
  include ApolloFederation::Schema
  # federation version: '2.0'
  use ApolloFederation::Tracing
  # orphan_types ProductType
  # orphan_types ProductSearchByCriteriaBlob
  query QueryType
end

# Define a simple Sinatra app to handle the GraphQL requests
class MyApp < Sinatra::Base
  before do
    content_type 'application/json'
  end

  post '/graphql' do
    request_payload = JSON.parse(request.body.read)
    result = MySchema.execute(request_payload['query'], variables: request_payload['variables'])
    status 200
    p result.to_json
  end
end

puts "*"*20
schema = MySchema.federation_sdl
puts schema
File.open('data.schema', 'w') { |file| file.write(schema) }
puts "*"*20
