RSpec.describe 'Payload specs' do
  Dir[File.join(root_path, 'payloads/*')].each do |operation_id|
    next if operation_id.split('/')[-1] == 'france_connect'

    describe "operation #{operation_id.split('/')[-1]}" do
      Dir[File.join(operation_id, '*.yaml')].each do |payload|
        describe "Payload #{File.basename(payload)}" do
          it 'is a valid YAML file' do
            expect { YAML.load_file(payload) }.not_to raise_error
          end

          it 'has a valid json for "payload" key' do
            data = YAML.load_file(payload)

            expect { JSON.parse(data['payload']) }.not_to raise_error
          end

          it 'has a valid status code' do
            data = YAML.load_file(payload)

            expect([200, 400, 401, 403, 404, 502]).to include(data['status'])
          end

          it 'has valid params according to OpenAPI file' do
            params = YAML.load_file(payload)['params']
            path_spec = extract_path_spec_from_schema(File.basename(operation_id), load_schema(operation_id))

            schema = {
              type: 'object',
              required: params.keys.reject { |param| path_spec['parameters'].find { |p| p['name'] == param }['required'] == false },
              properties: path_spec['parameters'].each_with_object({}) do |param_spec, acc|
                acc[param_spec['name']] = param_spec['schema']
              end
            }

            test = JSON::Validator.fully_validate(schema, params)
            expect(test).to be_empty, "JSON schema validation failed: #{test}"
          end

          it 'has a valid payload according to OpenAPI file' do
            data = YAML.load_file(payload)
            path_spec = extract_path_spec_from_schema(File.basename(operation_id), load_schema(operation_id))

            schema = path_spec['responses'][data['status'].to_s]['content']['application/json']['schema']

            test = JSON::Validator.fully_validate(schema, JSON.parse(data['payload']))
            expect(test).to be_empty, "JSON schema validation failed: #{test}"
          end
        end
      end
    end
  end
end
