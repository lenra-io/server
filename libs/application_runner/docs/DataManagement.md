# CRUD

Create a document, give the content in the body
```js
- POST `${api.url}/app/colls/${coll}/docs`
```
Read a specific document
```js
- GET `${api.url}/app/colls/${coll}/docs/${id}`
```
Update a document, give the changes in the body
```js
- PUT `${api.url}/app/colls/${coll}/docs/${doc._id}`
```
Delete a document
```js
- DELETE `${api.url}/app/colls/${coll}/docs/${doc._id}`
```
  
# How listener changes the data

```mermaid
flowchart
    Client -- 1 --> webserver["Web server"]
    webserver -- 2 --> Application
    Application -- 3 --> DataApi["Data API"]
    Mongo --- DataApi
    DataApi -- 4 --> Application
    Mongo[(Mongo)]

    id1["1 - Listener actionned\n 2 - Run listener\n 3 - Change data\n 4 - Updated data"]

```

# How are the views reloaded

```mermaid
graph
    Mongo[(Mongo)]
    Mongo -- 1 --> QueryServer["Query Server*"]
    QueryServer -- 2 --> QueryParser["Query Parser"]
    QueryParser -- 3 --> QueryServer
    QueryServer -- 4 --> ViewServer["View Server*"]
    ViewServer -- 5 --> Application
    Application -- 6 --> ViewServer
    ViewServer -- 7 --> QueryServer
    QueryServer -- 8 --> RouteServer["Route Server*"]
    RouteServer -- 9 --> Client
    subgraph Server
        QueryServer
        ViewServer
        RouteServer
    end

    id1["1 - Mongo Event\n 2 - Check if Query are concerned\n 3 - Return a boolean\n 4 - Request reload cache\n 5 - Call view with new Data\n 6 - Return new JSON\n 7 - Respond when cache reloaded\n 8 - Tell Route server that ui changed\n 9 - Send patch Ui to client\n\n * - Many thread server"]  
```
    
