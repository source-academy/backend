defmodule Cadet.AwsHelper do
  @moduledoc """
  Contains some methods to workaround silly things in ExAws.
  """

  def request(operation = %ExAws.Operation.RestQuery{}, headers, config_overrides) do
    config = ExAws.Config.new(operation.service, config_overrides)
    url = ExAws.Request.Url.build(operation, config)

    result =
      ExAws.Request.request(
        operation.http_method,
        url,
        operation.body,
        headers,
        config,
        operation.service
      )

    operation.parser.(result, operation.action)
  end
end
