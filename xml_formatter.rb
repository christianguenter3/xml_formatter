require 'HTTPClient'
require 'htmlentities'
require 'clipboard'

class XMLFormatter
	NEW_FILE_NAME   = Random.new_seed.to_s
	TEMPLATE_STRING = '<x>DUMMY</x>'

	def initialize
		@http = HTTPClient.new
	end

	def format(input_string)
		File.open(NEW_FILE_NAME,'w+') do |new_file|
			File.open('Template').each_line do |line|
				if line =~ /#{TEMPLATE_STRING}/
					new_file.puts input_string
				else
					new_file.puts line
				end
			end
		end

		file = File.open(NEW_FILE_NAME)

		body = { 'Content-Type'   => "multipart/form-data; boundary=----WebKitFormBoundaryaExhdJjsvTcZzvht",
				 'Host' 		  => 'www.freeformatter.com' }

		@http.post("http://www.freeformatter.com/xml-formatter.html",file,body)

		if @http.get("http://www.freeformatter.com/xml-formatter.html#ad-output").content =~ %r{<pre id="xmlOutput" class="xml prettyprint">(.*?)</pre>}m
			result = HTMLEntities.new.decode($1)
		end

		file.close
		File.delete(NEW_FILE_NAME)

		result
	end
end

if ARGV[0]
	formatter = XMLFormatter.new	
	Clipboard.copy(formatter.format(Clipboard.paste.split(/\n/)))
else
	require 'Test/Unit'
	class TestXMLFormatter < Test::Unit::TestCase
		def test_format		
			formatted_string = XMLFormatter.new.format('<test>YYY<y>1</y></test>')
			assert_not_equal(nil, formatted_string =~ /<\?xml version="1.0" encoding="UTF-8"\?>/)
			assert_not_equal(nil, formatted_string =~ /YYY/)
			assert_not_equal(nil, formatted_string =~ /<y>1<\/y>/)
		end
	end
end