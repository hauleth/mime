defmodule MIME do
  @moduledoc """
  Maps MIME types to its file extensions and vice versa.

  MIME types can be extended in your application configuration
  as follows:

      config :mime, :types, %{
        "application/vnd.api+json" => ["json-api"]
      }

  After adding the configuration, MIME needs to be recompiled.
  If you are using mix, it can be done with:

      $ mix deps.clean mime --build
      $ mix deps.get
  """

  @compile :no_native
  @external_resource "lib/mime.types"

  stream = File.stream!("lib/mime.types")

  mapping = Enum.flat_map(stream, fn(line) ->
    if String.starts_with?(line, ["#", "\n"]) do
      []
    else
      [type|exts] = line |> String.strip |> String.split
      [{type, exts}]
    end
  end)

  app = Application.get_env(:mime, :types, %{})

  @doc """
  Returns whether a MIME type is registered.

  ## Examples

      iex> MIME.valid?("text/plain")
      true

      iex> MIME.valid?("foo/bar")
      false

  """
  @spec valid?(String.t) :: boolean
  def valid?(type) do
    is_list(entry(type))
  end

  @doc """
  Returns the extensions associated with a given MIME type.

  ## Examples

      iex> MIME.extensions("text/html")
      ["html", "htm"]

      iex> MIME.extensions("application/json")
      ["json"]

      iex> MIME.extensions("foo/bar")
      []

  """
  @spec extensions(String.t) :: [String.t]
  def extensions(type) do
    entry(type) || []
  end

  @default_type "application/octet-stream"

  @doc """
  Returns the MIME type associated with a file extension. If no MIME type is
  known for `file_extension`, `#{inspect @default_type}` is returned.

  ## Examples

      iex> MIME.type("txt")
      "text/plain"

      iex> MIME.type("foobarbaz")
      #{inspect @default_type}

  """
  @spec type(String.t) :: String.t
  def type(file_extension)

  # The ones from the app always come first.
  for {type, exts} <- app, ext <- List.wrap(exts) do
    def type(unquote(ext)), do: unquote(type)
  end

  for {type, exts} <- mapping, ext <- exts do
    def type(unquote(ext)), do: unquote(type)
  end

  def type(_ext), do: @default_type

  @doc """
  Returns whether an extension has a MIME type registered.

  ## Examples

      iex> MIME.type_known?("txt")
      true

      iex> MIME.type_known?("foobarbaz")
      false

  """
  @spec type_known?(String.t) :: boolean
  def type_known?(file_extension)

  for {_type, exts} <- app, ext <- List.wrap(exts) do
    def type_known?(unquote(ext)), do: true
  end

  for {_type, exts} <- mapping, ext <- exts do
    def type_known?(unquote(ext)), do: true
  end

  def type_known?(_ext), do: false

  @doc """
  Guesses the MIME type based on the path's extension. See `type/1`.

  ## Examples

      iex> MIME.from_path("index.html")
      "text/html"

  """
  @spec from_path(Path.t) :: String.t
  def from_path(path) do
    case Path.extname(path) do
      "." <> ext -> type(downcase(ext, ""))
      _ -> @default_type
    end
  end

  defp downcase(<<h, t::binary>>, acc) when h in ?A..?Z, do: downcase(t, <<acc::binary, h+32>>)
  defp downcase(<<h, t::binary>>, acc), do: downcase(t, <<acc::binary, h>>)
  defp downcase(<<>>, acc), do: acc

  @spec entry(String.t) :: list(String.t)
  defp entry(type)

  for {type, exts} <- app do
    defp entry(unquote(type)), do: unquote(List.wrap(exts))
  end

  for {type, exts} <- mapping do
    defp entry(unquote(type)), do: unquote(exts)
  end

  defp entry(_type), do: nil
end
