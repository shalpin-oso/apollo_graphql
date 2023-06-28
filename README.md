# apollo_graphql

gem install sinatra graphql apollo-federation
gem install solargraph
gem install bundler bundle
gem install webrick
gem install json

# curl search api 

```
curl -X POST \
-H "Content-Type: application/json" \
-d '{
  "query": "query ExampleQuery($input: ProductSearchInput!) { products(input: $input) { id name } }",
  "variables": {
    "input": {
      "query": "mug"
    }
  }
}' \
https://sean-halpin-studious-space-telegram-pq9w549pq9f7rp-4567.preview.app.github.dev/graphql
```
