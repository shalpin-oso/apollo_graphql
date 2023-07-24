require 'sinatra'
require 'graphql'
require 'json'
require 'apollo-federation'
require 'webrick'

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
  extend_type

  key fields: :id
  
  field :id, String, null: false, external: false
end

class ProductSearchInput < GraphQL::Schema::InputObject
  include ApolloFederation::InputObject

  argument :query, String, required: true
end

class ProductSearchQuery < GraphQL::Schema::Resolver
  type [ProductType], null:false
  argument :criteria, ProductSearchInput, required: true

  def resolve(args)
   p args
   p product_db 100
  end
end 

class QueryType < BaseObject
  include ApolloFederation::Object

  # field :product_search_query, resolver: ProductSearchQuery, connection: false
  field :product_search_query, [ProductType], null: false do
    argument :query, ProductSearchInput, required: true
  end

  # Implement the resolver for the productSearchQuery query
  def product_search_query(query:)
    # In a real scenario, you would use the criteria to search for products
    # For this example, we'll just return all products for simplicity
    product_db 0
  end
end

class ProductSearchByCriteriaBlob < BaseObject
  include ApolloFederation::Object

  key fields: :query
  field :query, String, null: false, external: false
  field :products, [ProductType], null: false

  def products
    p 'ProductSearchByCriteriaBlob::products'
    p object
    p product_db 0
  end
end

class MySchema < GraphQL::Schema
  include ApolloFederation::Schema
  # federation version: '2.0'
  use ApolloFederation::Tracing
  orphan_types ProductSearchByCriteriaBlob
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
File.open('search.schema', 'w') { |file| file.write(schema) }
puts "*"*20
