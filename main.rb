# frozen_string_literal: true

require "http"
require_relative "reports_pb"

module ApolloProofOfConcept
  module_function

  def generate_full_report
    raise "Missing APITOKEN" unless ENV["APITOKEN"]

    start_time = Time.now.utc
    end_time = Time.now.utc

    trace = Trace.new(
      start_time: start_time,
      end_time: end_time,
      duration_ns: ((end_time - start_time) * 1e9).to_i.abs,
      client_name: "c1",
      client_version: "v1",
      http: Trace::HTTP.new(
        method: "POST"
      ),
      root: Trace::Node.new(
        response_name: "user",
        original_field_name: "user",
        type: "User!",
        parent_type: "Query",
        child: [
          ::Trace::Node.new(
            response_name: "email",
            original_field_name: "email",
            type: "String!",
            start_time: 11,
            end_time: 12,
            parent_type: "User"
          )
        ]
      )
    )

    schema = "# Foo\nquery Foo { user { email } }"

    report = FullTracesReport.new(
      header: ReportHeader.new(
        hostname: "www.example.com",
        schema_tag: "staging",
        schema_hash: "alskncka384u1923e8uino1289jncvo019n"
      )
    )
    report.traces_per_query[schema] = Traces.new(trace: [trace])

    report
  end

  def run
    report = generate_full_report

    puts JSON.pretty_generate(JSON.parse(FullTracesReport.encode_json(report)))

    endpoint = "https://engine-report.apollodata.com/api/ingress/traces"
    token = ENV["APITOKEN"]

    body = report.to_proto

    HTTP.
      # use(auto_deflate: { method: :gzip }). # enable to compact body as gzip
      headers(
        "user-agent" => "apollo-engine-reporting",
        "x-api-key" => token
      ).
      post(endpoint, body: body)
  end
end

result = ApolloProofOfConcept.run
puts result.inspect
puts result
