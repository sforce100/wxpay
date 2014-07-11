require 'multi_xml'
require 'ostruct'

module WxHelper
  module XmlHelper
  # <xml>
  #   <AppId><![CDATA[wwwwb4f85f3a797777]]></AppId>
  #   <OpenId><![CDATA[111222]]></OpenId>
  #   <IsSubscribe>1</IsSubscribe>
  #   <ProductId><![CDATA[777111666]]></ProductId>
  #   <TimeStamp> 1369743908</TimeStamp>
  #   <NonceStr><![CDATA[YvMZOX28YQkoU1i4NdOnlXB1]]></NonceStr>
  #   <AppSignature><![CDATA[a9274e4032a0fec8285f147730d88400392acb9e]]></AppSignat
  #   ure>
  #   <SignMethod><![CDATA[sha1]]></ SignMethod >
  # </xml>
    def get_package_post_data post_data
      Message.new(post_data)
    end

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
            @time_stamp = Time.now.to_i
            @ret_code = 0
            @sign_method = "sha1"
            @ret_err_msg = "ok"
        end

        def to_xml
           super.to_xml(:encoding => 'UTF-8', :indent => 0, :save_with => 0)
        end
    end

  end
end