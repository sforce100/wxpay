require 'multi_xml'
require 'ostruct'

module WxHelper
  module XmlHelper

    class Message
      def initialize(xml)
        hash = parse_xml xml
        @source = OpenStruct.new(hash['xml']) 
      end

      def method_missing(method, *args, &block)
        @source.send(method.to_s.classify, *args, &block)
      end

      def parse_xml xml
        MultiXml.parse(xml)
      end
    end

    # <xml>
    # <AppId><![CDATA[wwwwb4f85f3a797777]]></AppId>
    # <Package><![CDATA[a=1&url=http%3A%2F%2Fwww.qq.com]]></Package>
    # <TimeStamp> 1369745073</TimeStamp>
    # <NonceStr><![CDATA[iuytxA0cH6PyTAVISB28]]></NonceStr>
    # <RetCode>0</RetCode>
    # <RetErrMsg><![CDATA[ok]]></ RetErrMsg>
    # <AppSignature><![CDATA[53cca9d47b883bd4a5c85a9300df3da0cb48565c]]>
    # </AppSignature>
    # <SignMethod><![CDATA[sha1]]></ SignMethod >
    # </xml>    
    PackageMessage = Class.new(Message)
    
    # <xml>
    # <OpenId><![CDATA[111222]]></OpenId>
    # <AppId><![CDATA[wwwwb4f85f3a797777]]></AppId>
    # <IsSubscribe>1</IsSubscribe>
    # <TimeStamp> 1369743511</TimeStamp>
    # <NonceStr><![CDATA[jALldRTHAFd5Tgs5]]></NonceStr>
    # <AppSignature><![CDATA[bafe07f060f22dcda0bfdb4b5ff756f973aecffa]]>
    # </AppSignature>
    # <SignMethod><![CDATA[sha1]]></ SignMethod >
    # </xml>
    NotifyMessage = Class.new(Message)

    class ResponseMessage
        include ROXML
        xml_name :xml
        xml_convention :camelcase

        xml_accessor :app_id, :cdata => true
        xml_accessor :package, :cdata => true
        xml_accessor :nonce_str, :cdata => true
        xml_accessor :ret_err_msg, :cdata => true
        xml_accessor :app_signature, :cdata => true
        xml_accessor :sign_method, :cdata => true
        xml_accessor :time_stamp, :as => Integer
        xml_accessor :ret_code, :as => Integer
        def initialize
          @sign_method = "sha1"
        end

        def to_xml
           super.to_xml(:encoding => 'UTF-8', :indent => 0, :save_with => 0)
        end
    end

  end
end