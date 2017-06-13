module ReplaceInFile
  def replace_in_file(file_path, pattern, replacement)
    file_content     = File.read(file_path)
    new_file_content = file_content.gsub(pattern, replacement)
    File.write(file_path, new_file_content)
  end
end

RSpec.configure do
  include ReplaceInFile
end
