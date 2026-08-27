<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="3.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:template match="/">
    <ns0:Receivers xmlns:ns0="http://sap.com/xi/XI/System">
      <ReceiverNotDetermined>
        <Type>Error</Type>
        <DefaultReceiver/>
      </ReceiverNotDetermined>
      <xsl:if test="/*:MaintenanceOrder/MaintenanceOrderType/MaintenanceOrderType = 'YBA1'">
        <Receiver>
          <Service>Receiver_AssetRegistry</Service>
          <Interfaces><Interface><Index>1</Index><Service>/PIP_WY/PRD/Step07/MaintenanceOrder/Receiver_AssetRegistry</Service></Interface></Interfaces>
        </Receiver>
        <Receiver>
          <Service>Receiver_Crow</Service>
          <Interfaces><Interface><Index>1</Index><Service>/PIP_WY/PRD/Step07/MaintenanceOrder/Receiver_Crow</Service></Interface></Interfaces>
        </Receiver>
      </xsl:if>
    </ns0:Receivers>
  </xsl:template>
</xsl:stylesheet>
