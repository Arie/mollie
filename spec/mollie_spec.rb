require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Mollie do
  
  describe Mollie::SMS do

    def accepts(attribute, checked_attribute = nil)
      checked_attribute ||= attribute
      subject = Mollie::SMS.new(attribute => 'xxx')
      subject.__send__(checked_attribute).should == 'xxx'
      subject.__send__("#{attribute}=", 'yyy')
      subject.__send__(checked_attribute).should == 'yyy'
    end

    def self.should_accept(attribute, checked_attribute = nil)
      it "should accept #{attribute} #{checked_attribute ? "and store it as #{checked_attribute}" : ""}" do
        accepts(attribute, checked_attribute)
      end
    end

    should_accept :username
    should_accept :password
    should_accept :message
    should_accept :originator
    should_accept :gateway
    should_accept :md5_password
    should_accept :delivery_url
    should_accept :message_type
    should_accept :udh
    should_accept :receipt
    should_accept :uri
    should_accept :deliver_at

    it "should know a default gateway" do
      Mollie::SMS.new.uri.should == Mollie::RequestOptions::DEFAULT_URI
    end

    it "should accept a single recipient" do
      subject = Mollie::SMS.new(:recipients => ['x', 'y'])
      subject.recipient = 'z'
      subject.recipients.should == ['z']
    end

  end

  describe Mollie::Query do

    it "should format deliverydate as yyyymmddhhmmss" do
      date = DateTime.civil(2009, 3, 8, 1, 3, 4).to_s
      Mollie::Query.new(Mollie::SMS.new(:deliver_at => date)).deliverydate.should == "20090308010304"
    end

    it "should get a comma seperated list of recipients" do
      subject = Mollie::Query.new(Mollie::SMS.new(:recipients => [ "alice", "bob" ]))
      subject.recipients.should == "alice,bob"
    end

    it "should return an uri to get" do
      subject = Mollie::Query.new(Mollie::SMS.new(:username => 'un', :password => 'pw', :message => 'msg', :recipients => ['alice','charles'], :originator => 'bob', :uri => 'http://gateway', :gateway => "4", :udh => "bla", :receipt => "yesplease", :message_type => "123")).request_uri.to_s
      subject.should =~ /\busername=un\b/
      subject.should =~ /\Ahttp:\/\/gateway\?/
      subject.should =~ /\bpassword=pw\b/
      subject.should =~ /\bmessage=msg\b/
      subject.should =~ /\brecipients=alice,charles\b/
      subject.should =~ /\boriginator=bob\b/
      subject.should =~ /\bgateway=4\b/
      subject.should =~ /\breturn=yesplease\b/
      subject.should =~ /\btype=123\b/
      subject.should =~ /\budh=bla\b/
    end

  end

  describe Mollie::Send do

    it "should accept a result code 10 as success" do
      query = mock("query")
      query.stub!(:request_uri).and_return(URI.parse("http://blah"))
      FakeWeb.register_uri(:get, /.*/, :body => xml_ellende(10))
      Mollie::Send.send(query).should be_success
    end


    it "should raise an exception when resultcode is not 10" do
      query = mock("query")
      query.stub!(:request_uri).and_return(URI.parse("http://blash"))
      FakeWeb.register_uri(:get, /.*/, :body => xml_ellende(20))
      lambda { Mollie::Send.send(query) }.should raise_error(Mollie::MollieException)
    end
    
  end

def xml_ellende(resultcode=10)
%Q|
<?xml version="1.0" ?>
<response>
    <item type="sms">
        <recipients>1</recipients>
        <success>true</success>
        <resultcode>#{resultcode}</resultcode>
        <resultmessage>Message successfully sent.</resultmessage>
    </item>
</response> 
|
end

end
