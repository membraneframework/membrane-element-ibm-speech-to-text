defmodule Membrane.Element.GCloud.SpeechToText.IntegrationTest do
  use ExUnit.Case

  alias Membrane.Testing
  alias IBMSpeechToText.{RecognitionAlternative, RecognitionResult, Response}
  alias Membrane.Element.{FLACParser, IBMSpeechToText}

  import Membrane.Testing.Assertions

  @moduletag :external

  @fixture_path "../fixtures/sample.flac" |> Path.expand(__DIR__)

  test "recognition pipeline provides transcription of short file" do
    assert {:ok, pid} =
             Testing.Pipeline.start_link(%Testing.Pipeline.Options{
               elements: [
                 src: %Membrane.File.Source{location: @fixture_path},
                 parser: FLACParser,
                 sink: %IBMSpeechToText{
                   region: Application.get_env(:ibm_speech_to_text, :region, :frankfurt),
                   api_key: Application.get_env(:ibm_speech_to_text, :api_key),
                   recognition_options: [interim_results: false]
                 }
               ]
             })

    assert :ok = Testing.Pipeline.play(pid)

    assert_end_of_stream(pid, :sink, :input, 10_000)

    assert_pipeline_notified(pid, :sink, %Response{} = response, 10_000)

    assert response.result_index == 0
    assert [%RecognitionResult{alternatives: [alternative]}] = response.results
    assert %RecognitionAlternative{} = alternative

    assert alternative.transcript =~
             "adventure one a scandal in Bohemia from the adventures of Sherlock Holmes by Sir Arthur Conan Doyle"
  end
end
