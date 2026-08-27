# Combined Receiver and Interface Determination XSLT

For integrated async recipient-list routing, preserve the expected XI namespace and complete output hierarchy. The following structure is the validated user-supplied pattern. Adapt only source XPath, receiver aliases, names, and Step07 addresses.

```xml
<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="3.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:template match="/">
    <ns0:Receivers xmlns:ns0="http://sap.com/xi/XI/System">
      <ReceiverNotDetermined>
        <Type>Error</Type>
        <DefaultReceiver/>
      </ReceiverNotDetermined>
      <xsl:if test="/*:MaintenanceOrder/MaintenanceOrderType/MaintenanceOrderType = 'YBA1'">
        <Receiver>
          <Service>Receiver_AssetRegistry</Service>
          <Interfaces>
            <Interface>
              <Index>1</Index>
              <Service>/PIP_WY/PRD/Step07/MaintenanceOrder/Receiver_AssetRegistry</Service>
            </Interface>
          </Interfaces>
        </Receiver>
        <Receiver>
          <Service>Receiver_Crow</Service>
          <Interfaces>
            <Interface>
              <Index>1</Index>
              <Service>/PIP_WY/PRD/Step07/MaintenanceOrder/Receiver_Crow</Service>
            </Interface>
          </Interfaces>
        </Receiver>
      </xsl:if>
    </ns0:Receivers>
  </xsl:template>
</xsl:stylesheet>
```

Rules:
- Multiple `Receiver` nodes implement a recipient list.
- Multiple `Interface` nodes implement interface split for a receiver.
- `Service` under `Receiver` is the receiver alias.
- `Service` under `Interface` is the Step07 ProcessDirect address in this pattern.
- Do not omit `ReceiverNotDetermined`.
- Select Error, Ignore, or Default deliberately and explain runtime consequences.
- Mark examples illustrative if the deployed package schema has not been inspected.
