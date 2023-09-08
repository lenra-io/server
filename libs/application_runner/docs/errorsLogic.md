# How to manage errors on Lenra

### Error Level

- emergency: when the system cannot be used (ex : openfass_not_reachable after 5 attempts)  
- alert: something is wrong and need our attention, (ex: openfass_not_reachable less than 5 - times, mongo_connection, ecto connection error, ...)  
- critical: when the error can make the system crash (ex: view genserver crash/query genserver crash), basically we can wrap this error in a try/catch  
- error: normal error  
- warning: something is wrong but it does not impact the workflow  
- notice: highlight a message  
- info: info message (ex: socket started, channel_started)  
- debug: debug message  

### Best Practices
- All errors will be logged with `Logger` and sent to Sentry.

- For a debug message see the Debug section below for examples, from warning level prefer using an Error struct

- In case we need to make a treatment for the error message of the Logger, we can use:

>The fn inside the Logger will be executed only if the log level is set to debug.

```elixir
Logger.debug(fn -> "params: #{inspect(params)}" end)
# Instead of
Logger.debug("params: #{inspect(params)}")
```

> or use telemetry event to do it asynchronously

- try to log the error on the deepest function, and try to not duplicate Log (ex: don't log errors of the child in the parent function if the child already logs it)

### Debug

#### Controller

```elixir
#Start
Logger.debug(
        "#{__MODULE__} handle #{inspect(conn.method)} on #{inspect(conn.request_path)} with path_params #{inspect(conn.path_params)} and body_params #{inspect(conn.body_params)}"
      )
#End
Logger.debug(
        "#{__MODULE__} respond to #{inspect(conn.method)} on #{inspect(conn.request_path)} with res #{inspect(<res>)}"
      )
```

#### Function
```elixir
#Start
Logger.debug("#{__MODULE__} start_link with #{env_metadata}")
#End
Logger.debug("#{__MODULE__} start_link exit with #{inspect(res)}")
```


### Genserver

We need to focus on Genserver stability, see genserver [docs](docs/errorsLogic.md) for more info.

Some rules:
- Add default function for all pattern match, raise warning/error/critical following the case
- In our business logic we sometimes need to also send a message to the websocket, notify the user something happened
- All Genserver calls need to be wrapped in a try/rescue, for now we just log an error and notify users to reload the app, in the future we could try to restart the genserver

### Alert/Emergency error  
  
Alert messages are sent when a problem needs our attention, some examples:
- Openfaas not reachable/timeout
- Postgres/Mongo not reachable
- Function not found in Openfaas, this can normally NEVER happen in our workflow
- (In the same idea), mongo_user_idea not found normally created on the first launch of the environment if we cannot find it later this is an alert, this should NEVER happen in normal ways

Use telemetry event to send alerts, after 5 alerts telemetry sends an emergency error.