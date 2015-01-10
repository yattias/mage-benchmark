# Simple script to benchmark DB vs API performance in magento
# Feel free to customize

require 'savon'
require 'benchmark'
require 'mysql'

num_iterations = 50
mage_soap_api_uri = 'http://magento.com/api/soap/?wsdl'
mage_api_user = 'user' # This needs to be set up in magento admin
mage_api_key = 'api_key' # This needs to be set up in magento admin
customer_id = 1794

db_host = 'localhost'
db_username = 'magento'
db_password = ''
db_name = 'magento'

def bench_mage_api(mage_soap_api_uri, mage_api_user, mage_api_key, customer_id, num_iterations)
	client = Savon.client(wsdl: mage_soap_api_uri)
	response = client.call(:login, :message => { :username => mage_api_user, :apiKey => mage_api_key })
	session_id = response.body[:login_response][:login_return]

	b_api = Benchmark.measure do
		(1..num_iterations).each do
			client.call(:call, :message => {:session => session_id, :method => 'customer.info', :customerId => customer_id} )
		end
	end

	b_api.real
end

def bench_mage_db(host, username, password, db_name, customer_id, num_iterations)
	con = Mysql.new(host, username, password, db_name, customer_id)
	rs = con.query("select * from customer_entity where entity_id=#{customer_id}")

	b_sql = Benchmark.measure do
		(1..num_iterations).each do
			con.query("select * from customer_entity where entity_id=#{customer_id}")
		end
	end

	con.close
	b_sql.real
end

t = bench_mage_api(mage_soap_api_uri, mage_api_user, mage_api_key, customer_id, num_iterations)
t2 = bench_mage_db(db_host, db_username, db_password, db_name, customer_id, num_iterations)
puts "API Time: #{t}"
puts "Mysql Time: #{t2}"
