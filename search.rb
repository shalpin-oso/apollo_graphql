require 'sinatra'
require 'graphql'
require 'json'
require 'apollo-federation'

# Define your GraphQL schema
class ProductType < GraphQL::Schema::Object
  include ApolloFederation::Object

  field :id, ID, null: false
  field :name, String, null: false
end

class ProductSearchInput < GraphQL::Schema::InputObject
  include ApolloFederation::InputObject

  argument :query, String, required: true
end

class SortOrderInput < GraphQL::Schema::InputObject
  include ApolloFederation::InputObject

  argument :direction, String, required: true
  argument :field, String, required: true
end

class QueryType < GraphQL::Schema::Object
  include ApolloFederation::Object

  field :products, [ProductType], null: false do
    argument :input, ProductSearchInput, required: true
  end

  def products(input:)
    # Simulated logic to return a list of products based on the input
    [
      { id: 1, name: "Mug 1" },
      { id: 2, name: "Mug 2" },
      { id: 3, name: "Mug 3" }
    ]
  end
end

class MySchema < GraphQL::Schema
  include ApolloFederation::Schema
  include GraphQL::Introspection

  query QueryType
end

# Define a simple Sinatra app to handle the GraphQL requests
class MyApp < Sinatra::Base
  post '/graphql' do
    request_payload = JSON.parse(request.body.read)
    result = MySchema.execute(request_payload['query'], variables: request_payload['variables'])
    JSON.dump result
  end
end

# Run the Sinatra app
MyApp.run!
