require 'rack'
require 'rack-graphiql'
require_relative '../search'

map '/graphiql' do 
    run Rack::GraphiQL.new(endpoint: 'graphql')
end

run MyApp
