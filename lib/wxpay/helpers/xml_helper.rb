require 'multi_xml'
require 'ostruct'
require 'roxml'

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

    # <xml>
    # <OpenId><![CDATA[111222]]></OpenId>
    # <AppId><![CDATA[wwwwb4f85f3a797777]]></AppId>
    # <TimeStamp> 1369743511</TimeStamp>
    # <MsgType><![CDATA[request]]></MsgType>
    # <FeedBackId><![CDATA[5883726847655944563]]></FeedBackId>
    # <TransId><![CDATA[10123312412321435345]]></TransId>
    # <Reason><![CDATA[商品质量有问题]]></Reason>
    # <Solution><![CDATA[补发货给我]]></Solution>
    # <ExtInfo><![CDATA[明天六点前联系我 18610847266]]></ExtInfo>
    # <AppSignature><![CDATA[bafe07f060f22dcda0bfdb4b5ff756f973aecffa]]>
    # </AppSignature>
    # <SignMethod><![CDATA[sha1]]></ SignMethod >
    # </xml> 
    # <xml>
    # <OpenId><![CDATA[111222]]></OpenId>
    # <AppId><![CDATA[wwwwb4f85f3a797777]]></AppId>
    # <TimeStamp> 1369743511</TimeStamp>
    # <MsgType><![CDATA[confirm/reject]]></MsgType>
    # <FeedBackId><![CDATA[5883726847655944563]]></FeedBackId>
    # <Reason><![CDATA[商品质量有问题]]></Reason>
    # <AppSignature><![CDATA[bafe07f060f22dcda0bfdb4b5ff756f973aecffa]]>
    # </AppSignature>
    # <SignMethod><![CDATA[sha1]]></ SignMethod >
    # </xml>
    PayFeedbackMessage = Class.new(Message)

    # <xml>
    # <AppId><![CDATA[wxf8b4f85f3a794e77]]></AppId>
    # <ErrorType>1001</ErrorType>
    # <Description><![CDATA[错识描述]]></Description>
    # <AlarmContent><![CDATA[错误详情]]></AlarmContent>
    # <TimeStamp>1393860740</TimeStamp>
    # <AppSignature><![CDATA[f8164781a303f4d5a944a2dfc68411a8c7e4fbea]]></AppSignature>
    # <SignMethod><![CDATA[sha1]]></SignMethod>
    # </xml>
    WarningMessage = Class.new(Message)

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