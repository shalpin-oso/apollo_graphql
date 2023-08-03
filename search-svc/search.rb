require 'sinatra'
require 'graphql'
require 'json'
require 'apollo-federation'
require 'webrick'
require 'byebug'

def product_db(start)
  # Simulated logic to return a list of products based on the input
  [
    { id: start + 1},
    { id: start + 2}
  ]
end

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
end

class ProductSearchInput < GraphQL::Schema::InputObject
  include ApolloFederation::InputObject

  argument :query, String, required: true
end

class PageInput < GraphQL::Schema::InputObject
  include ApolloFederation::InputObject

  argument :page, String, required: true
end

class SearchQueryAndProducts < BaseObject
  include ApolloFederation::Object

  key fields: :query
  field :query, String, null: false, external: true
  field :products, [ProductType], null: false do
    argument :page, PageInput, required: true
  end

  def products(page)
    p 'SearchQueryAndProducts::products'
    p product_db page[:page][:page].to_i
  end
end

class MySchema < GraphQL::Schema
  include ApolloFederation::Schema
  # federation version: '2.0'
  use ApolloFederation::Tracing
  orphan_types SearchQueryAndProducts
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
File.open('search.schema', 'w') { |file| file.write(schema) }
puts "*"*20
