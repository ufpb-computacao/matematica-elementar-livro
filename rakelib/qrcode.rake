require 'yaml'

qrcode_dir = 'livro/images/qrcode'
qrcode_size = 4

desc "Build tables from qrcode specs"
task :qrcode
task :sync => :qrcode

QRCODE_DIR = 'livro/images/qrcode'

directory QRCODE_DIR

FileList['livro/capitulos/videos/*.yaml'].each do |source|
  tableadoc = source.ext('adoc')
  table = YAML.load_file(source)
  spec = table.delete 'spec'
  if spec then
    qrcode_size = spec['qrsize'] or qrcode_size
  end

  file tableadoc

  table.map do |label,media|
    if label == "end" then
    else
      link = media[0]
      qrcode_file_path = "#{qrcode_dir}/#{label}.png"
      file qrcode_file_path => [QRCODE_DIR, source] do
        sh "qrencode \"#{link}\" -o #{qrcode_file_path} -s #{qrcode_size}"
      end
      file tableadoc => [qrcode_file_path]
    end
  end

  file tableadoc => [source] do |t|
    cols = "1^"
    title = ""
    if spec then
      cols = spec['cols']
      qrcode_size = spec['qrsize'] or qrcode_size
      title = spec['title'] or title
    end
    table_file_id = File.basename(tableadoc).chomp(File.extname(tableadoc))
    tabela_id = "tabqr_#{table_file_id}"
    code = "[[#{tabela_id}]]\n"
    if (title) then
      code << ".#{title}\n"
    end
    header = "[cols=\"#{spec['cols']}\", frame=\"none\", grid=\"none\"]"
    code << header
    code << "\n|====\n"
    table.map do |label,media|

      if label == "end" then
        code << "| \n"
      else
        link = media[0]
        description = media[1]
        cellspec = media[2] or ""
        qrcode_file = "#{label}.png"
        sh "qrencode \"#{link}\" -o #{qrcode_dir}/#{qrcode_file} -s #{qrcode_size}"
        row = <<-eos
#{cellspec}| image:{qrcode_dir}/#{qrcode_file}[]

#{link}

#{description}
eos
        code << row

      end
    end
    code << "\n|====\n"
    #puts code
    File.open(tableadoc, 'w') {|f| f.write(code) }

    #puts table
    #sh "echo name #{t.name} source: #{t.source}"
    puts "\ninclude::videos/#{File.basename(tableadoc)}[]\n"
    puts "TIP: #{title}(<<#{tabela_id}>>).\n"
  end

  task :qrcode => tableadoc
end
