require Protocol
Protocol.derive(Jason.Encoder, ORY.Hydra.Response, only: [:body, :status_code])
